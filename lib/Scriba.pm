package Scriba;

use v5.16;
use strict;
use warnings;
use Carp;
use Encode qw(encode decode);
use Term::ReadKey;
use Unicode::Collate;
use utf8;
use open qw(:std :encoding(UTF-8));
use Data::Printer;

my $Collator = Unicode::Collate->new
  (normalization => undef, level => 1);
(my $terminal_width) = GetTerminalSize();
$terminal_width = $terminal_width - 5;
$terminal_width = 20 if $terminal_width < 20;

my %defaults =
  ( width     => $terminal_width,
    pagelines => 50000,
    header    => 1
  );
our %fmt;

sub accede {
  my $proto = shift;
  my $type  = ref($proto) || $proto;
  my $self  = {};
  my $width = $terminal_width;
  bless $self, $type;
  my %args; my %passed = @_;
  $args{ validate($_) } = $passed{$_} for keys %passed;
  %{ $self } = ( %{ $self }, %defaults, %args );

  $self->make_fmt();
  return $self;
}

sub audi {
  my $self = shift;
  my @lectiones = @_;
  my $lectio    = $lectiones[0];
  @lectiones > 3
    and die "Scriba cannot handle more than three texts!";
  not ref $_
    and die "$_ is not a reference" for @lectiones;
  $self->{lectiones} = \@lectiones;

  my $scriptum;
  open my $fh, '>', \$scriptum or die "Cannot open handle to string!";
  my $ofh = select $fh;
  local $| = 1;
  $= = $self->{pagelines};
  $^ = "CAPUT" if $self->{header};

  if (@lectiones == 1) {
    $~ = "SIMPLEX";
    for my $liber (keys %$lectio) {
      my @index = @{ $lectio->{$liber}{-1} };
      $fmt{lib} = $liber;
      for my $entry (@index) {
	$fmt{cap} = $entry->[0];
	$fmt{ver} = $entry->[1];
	$fmt{num} = "$fmt{cap}:$fmt{ver}";
	$fmt{txt} = $lectio->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	my $line = $scriptum ? ( () = $scriptum =~ /\n/g ) - 1 : 1;
	$self->{index}{$fmt{cap}}{$fmt{ver}} = $line;
	$self->{lineindex}{$line} = [$fmt{cap}, $fmt{ver}];
	write;
      }
    }
  }
  if (@lectiones == 2) {
    $~ = "DUPLEX";
    for my $liber (keys %$lectio) {
      my @index = @{ $lectio->{$liber}{-1} };
      $fmt{lib} = $liber;
      for my $entry (@index) {
	$fmt{cap} = $entry->[0];
	$fmt{ver} = $entry->[1];
	$fmt{num} = "$fmt{cap}:$fmt{ver}";
	$fmt{txt1} = $lectiones[0]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	$fmt{txt2} = $lectiones[1]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	my $line = $scriptum ? ( () = $scriptum =~ /\n/g ) - 1 : 1;
	$self->{index}{$fmt{cap}}{$fmt{ver}} = $line;
	$self->{lineindex}{$line} = [$fmt{cap}, $fmt{ver}];
	write;
      }
    }
  }
  if (@lectiones == 3) {
    $~ = "TRIPLEX";
    for my $liber (keys %$lectio) {
      my @index = @{ $lectio->{$liber}{-1} };
      $fmt{lib} = $liber;
      for my $entry (@index) {
	$fmt{cap} = $entry->[0];
	$fmt{ver} = $entry->[1];
	$fmt{num} = "$fmt{cap}:$fmt{ver}";
	$fmt{txt1} = $lectiones[0]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	$fmt{txt2} = $lectiones[1]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	$fmt{txt3} = $lectiones[2]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	my $line = $scriptum ? ( () = $scriptum =~ /\n/g ) - 1 : 1;
	$self->{index}{$fmt{cap}}{$fmt{ver}} = $line;
	$self->{lineindex}{$line} = [$fmt{cap}, $fmt{ver}];
	write;
      }
    }
  }
  select $ofh;
  close  $fh;
  $scriptum = decode('UTF8', $scriptum);
  $self->{scriptum}    = $scriptum;
  @{ $self->{lineae} } = split "\n", $scriptum;
  $self->{currens}     = 0;
  return \$scriptum;
}

sub exscribe {
  my $self  = shift;
  my $count = shift;
  return $self->{scriptum} unless $count;
  if ($self->{currens} == $#{ $self->{lineae} }) {
    $self->{finis} = 1;
    return undef;
  }

  my $locus = '';
  my $initium  = $self->{currens} + 1;
  my $finis    = $self->{currens} + $count;
  $finis = $#{ $self->{lineae} } if $finis > $#{ $self->{lineae} };
  $locus .= $self->{lineae}[$_]."\n" for $initium .. $finis;
  $self->{currens} = $finis;
  return $locus;
}

sub quaere {
  my $self = shift;
  my ($liber, $dir, $quaestio) = @_;
  my $positio;
  for my $index ( reverse sort numerically keys %{ $self->{lineindex} } ) {
    next if $index > $self->{currens};
    $positio = $self->{lineindex}{$index}; last;
  }
  for my $lectio (@{ $self->{lectiones} }) {
    my @capita = sort numerically keys %{ $lectio->{$liber} };
    if ($dir eq '?') {
      @capita = reverse @capita;
    }
    push @capita, shift @capita until $capita[0] == $positio->[0];
    push @capita, shift @capita;
    for my $caput (@capita) {
      next if $caput == -1;
      my @versus = sort numerically keys %{ $lectio->{$liber}{$caput} };
      if ($dir eq '?') {
	@versus = reverse @versus;
      }
      push @versus, shift @versus until $versus[0] == $positio->[1];
      push @versus, shift @versus;
      for my $versus (@versus) {
	my $txt = $lectio->{$liber}{$caput}{$versus};
	if ( $Collator->index($txt, $quaestio) != -1 ) {
	  $self->{currens} = $self->{index}{$caput}{$versus};
	  return $self->exscribe(1);
	}
      }
    }
  }
  return "No match!\n";
}

#--------------------------------------------------
# PRIVATE METHODS
#--------------------------------------------------

sub validate {
  my $key = shift;
  $key =~ s/-?(\w+)/\L$1/;
  return $key if exists $defaults{$key};
  die ("Configuration error in parameter: $key\n");
}

sub make_fmt {
  no warnings qw/redefine/;
  my $self = shift;
  my $screenwidth = $self->{width};
  my $txtwidth = $screenwidth - 8;
  my $format = '';

  # format CAPUT =
  # --------------------------------------------------
  # @|||||||||||||||||||||||||||||||||||||||||||||||||
  # "$lib $cap"
  # .
  # format SIMPLEX =
  # ^<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ~~
  # $num,  $txt
  # .

  # format DUPLEX =
  # ^<<<<< ^<<<<<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<< ~~
  # $num,  $txt1,              $txt2
  # .

  # format TRIPLEX =
  # ^<<<<< ^<<<<<<<< ^<<<<<<<<<<<< ^<<<<<<<<<<<<<< ~~
  # $num,  $txt1,    $txt2,        $txt3
  # .

  $format .=
    "format CAPUT =\n\n".
    "-" x $screenwidth  . "\n".
    "@" . "|" x ($screenwidth - 1) . "\n".
    '$fmt{lib}'."\n".
    "-" x $screenwidth  . "\n\n".
    ".\n\n";

  $format .=
    "format SIMPLEX =\n".
    '^<<<<<<' . ' ^'.'<'x($txtwidth - 1) . " ~~\n".
    '$fmt{num}, $fmt{txt}' . "\n".
    ".\n\n";

  $format .=
    "format DUPLEX =\n".
    '^<<<<<<'.
    ' ^'.'<'x($txtwidth / 2 - 2) .
    ' ^'.'<'x($txtwidth / 2 - 2) . " ~~\n".
    '$fmt{num}, $fmt{txt1}, $fmt{txt2}' . "\n".
    ".\n\n";

  $format .=
    "format TRIPLEX =\n".
    '^<<<<<<'.
    ' ^'.'<'x($txtwidth / 3 - 2) .
    ' ^'.'<'x($txtwidth / 3 - 2) .
    ' ^'.'<'x($txtwidth / 3 - 2) . " ~~\n".
    '$fmt{num}, $fmt{txt1}, $fmt{txt2}, $fmt{txt3}' . "\n".
    ".\n\n";
  eval $format;
}

sub numerically { $a <=> $b }

1;
