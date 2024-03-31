package Biblia::Scriba;

use v5.16;
use strict;
use warnings;
use Encode qw(encode decode);
use Term::ReadKey;
use Unicode::Normalize;
use utf8;
use open qw(:std :encoding(UTF-8));

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
    #$^ = "CAPUT_SIMPLEX" if $self->{header};
    $~ = "SIMPLEX";
    for my $liber (keys %$lectio) {
      my @index = @{ $lectio->{$liber}{-1} };
      $fmt{lib} = $liber;
      # $fmt{lib} = $lectio->{$liber}{-2};
      for my $entry (@index) {
	$fmt{cap} = $entry->[0];
	$fmt{ver} = $entry->[1];
	$fmt{num} = "$fmt{cap}:$fmt{ver}";
	$fmt{txt} = $lectio->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	my $start = $scriptum ? ( () = $scriptum =~ /\n/g ) - 1 : 1;
	write;
	my $end = ( () = $scriptum =~ /\n/g ) - 1;
	$self->{index}{$liber}{$fmt{cap}}{$fmt{ver}} = [$start, $end];
	$self->{lineindex}{$start} = [$liber, $fmt{cap}, $fmt{ver}];
      }
    }
  }
  if (@lectiones == 2) {
    $~ = "DUPLEX";
    #$^ = "CAPUT_DUPLEX" if $self->{header};
    for my $liber (keys %$lectio) {
      my @index = @{ $lectio->{$liber}{-1} };
      $fmt{lib} = $liber;
      # $fmt{lib1} = $lectiones[0]->{$liber}{-2};
      # $fmt{lib2} = $lectiones[1]->{$liber}{-2};
      for my $entry (@index) {
	$fmt{cap} = $entry->[0];
	$fmt{ver} = $entry->[1];
	$fmt{num} = "$fmt{cap}:$fmt{ver}";
	$fmt{txt1} = $lectiones[0]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	$fmt{txt2} = $lectiones[1]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	my $start = $scriptum ? ( () = $scriptum =~ /\n/g ) - 1 : 1;
	write;
	my $end = ( () = $scriptum =~ /\n/g ) - 1;
	$self->{index}{$liber}{$fmt{cap}}{$fmt{ver}} = [$start, $end];
	$self->{lineindex}{$start} = [$liber, $fmt{cap}, $fmt{ver}];
      }
    }
  }
  if (@lectiones == 3) {
    $~ = "TRIPLEX";
    #$^ = "CAPUT_TRIPLEX" if $self->{header};
    for my $liber (keys %$lectio) {
      my @index = @{ $lectio->{$liber}{-1} };
      $fmt{lib} = $liber;
      # $fmt{lib1} = $lectiones[0]->{$liber}{-2};
      # $fmt{lib2} = $lectiones[1]->{$liber}{-2};
      # $fmt{lib3} = $lectiones[2]->{$liber}{-2};
      for my $entry (@index) {
	$fmt{cap} = $entry->[0];
	$fmt{ver} = $entry->[1];
	$fmt{num} = "$fmt{cap}:$fmt{ver}";
	$fmt{txt1} = $lectiones[0]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	$fmt{txt2} = $lectiones[1]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	$fmt{txt3} = $lectiones[2]->{$fmt{lib}}{$fmt{cap}}{$fmt{ver}} || '';
	my $start = $scriptum ? ( () = $scriptum =~ /\n/g ) - 1 : 1;
	write;
	my $end = ( () = $scriptum =~ /\n/g ) - 1;
	$self->{index}{$liber}{$fmt{cap}}{$fmt{ver}} = [$start, $end];
	$self->{lineindex}{$start} = [$liber, $fmt{cap}, $fmt{ver}];
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

sub exscribe_lineas {
  my $self       = shift;
  my $count      = shift || return $self->{scriptum};
  my $standstill = shift;
  if ($self->{currens} >= $#{ $self->{lineae} }) {
    $self->{finis} = 1;
    return undef;
  }

  my $locus = '';
  my ($initium, $finis);
  if ($count > 0) {
    $initium  = $self->{currens} + 1;
    $finis    = $self->{currens} + $count;
    $finis = $#{ $self->{lineae} } if $finis > $#{ $self->{lineae} };
  }
  else {
    $finis    = $self->{currens} - 1;
    $initium  = $self->{currens} + $count;
    $initium  = 0 if $initium < 0;
    $finis    = 0 if $finis < 0;
  }
  $locus .= $self->{lineae}[$_]."\n" for $initium .. $finis;
  $self->{currens} = $finis unless $standstill;
  return $locus;
}

sub exscribe_versus {
  my $self  = shift;
  my $count = shift || return;
  --$count if $count>0;
  my $standstill = shift;
  my $positio = $self->get_positio($count);
  my ($liber, $caput, $versus)  = @$positio;
  my ($start, $end) = @{ $self->{index}{$liber}{$caput}{$versus} };
  my $lines = $end - $start;
  if ($count<0) {
    # set back cursor to first verse printed
    $self->{currens} = $start;
  }
  else {
    # first verse truncated to lines not yet printed
    $lines -= $self->{currens} - $start;
    # going back wraps, going forward ends session
    if ( $self->{currens} + $lines >= $#{ $self->{lineae} } ) {
      $self->{finis} = 1;
      $lines = $#{ $self->{lineae} } - $self->{currens};
    }
  }
  $self->exscribe_lineas($lines, $standstill);
}

sub revolve {
  my $self  = shift;
  my $count = shift;
  $self->{currens} -= $count;
  $self->{currens} = 0 if $self->{currens} < 0;
}

sub quaere {
  my $self = shift;
  my ($dir, $quaestio) = @_;
  $quaestio = strip_diacritics($quaestio);
  $quaestio = qr/\Q$quaestio\E/;
  my $positio = $self->get_positio();
  my ($liber, $caput, $versus)  = @$positio;

  my $lectio = $self->{lectiones}[0];
  # todo: one queue for all bibles
  my @queue;
  my @capita = sort numerically keys %{ $lectio->{$liber} };
  if ($dir eq '?') {
    @capita = reverse @capita;
  }
  push @capita, shift @capita until $capita[0] == $caput;
  for my $caput (@capita) {
    next if $caput < 0;
    my @versus = sort numerically keys %{ $lectio->{$liber}{$caput} };
    if ($dir eq '?') {
      @versus = reverse @versus;
    }
    for my $versus (@versus) {
      push @queue, [ $liber, $caput, $versus ];
    }
  }
  push @queue, shift @queue until $queue[0]->[2] == $versus;
  push @queue, shift @queue;
  for my $locus (@queue) {
    my ($lib, $cap, $vers) = @$locus;
    for my $editio ( @{ $self->{lectiones} } ) {
      my $txt = $editio->{$lib}{$cap}{$vers};
      $txt = strip_diacritics($txt);
      if ( $txt =~ $quaestio ) {
	$self->{currens} = $self->{index}{$lib}{$cap}{$vers}[0];
	return ($dir eq '?')
	  ? $self->exscribe_versus(1,1)
	  : $self->exscribe_versus(1);
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
    "format CAPUT_SIMPLEX =\n\n".
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
    "format CAPUT_DUPLEX =\n\n".
    "-" x $screenwidth  . "\n".
    " " x 7 .
    " @" . "|" x (($screenwidth - 8) / 2 - 2) .
    " @" . "|" x (($screenwidth - 8) / 2 - 2) ."\n".
    '$fmt{lib1}, $fmt{lib2}'."\n".
    "-" x $screenwidth  . "\n\n".
    ".\n\n";

  $format .=
    "format DUPLEX =\n".
    '^<<<<<<'.
    ' ^'.'<'x($txtwidth / 2 - 2) .
    ' ^'.'<'x($txtwidth / 2 - 2) . " ~~\n".
    '$fmt{num}, $fmt{txt1}, $fmt{txt2}' . "\n".
    ".\n\n";

  $format .=
    "format CAPUT_TRIPLEX =\n\n".
    "-" x $screenwidth  . "\n".
    " " x 7 .
    " @" . "|" x (($screenwidth - 8) / 3 - 3 ) .
    " @" . "|" x (($screenwidth - 8) / 3 - 3 ) .
    " @" . "|" x (($screenwidth - 8) / 3 - 3 ) . "\n".
    '$fmt{lib}, $fmt{lib2}, $fmt{lib3}' . "\n".
    "-" x $screenwidth  . "\n\n".
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

sub get_positio {
  my $self = shift;
  my $offset = shift || 0;
  my @indices = sort numerically keys %{ $self->{lineindex} };
  my $i;
  for ( reverse 0..$#indices ) {
    $i = $_;
    next      if $indices[$i] > $self->{currens};
    $offset-- if $offset < 0 and $indices[$i] == $self->{currens};
    last;
  }
  @indices = ( @indices[$i..$#indices], @indices[0..$i-1] );
  return $self->{lineindex}{$indices[$offset]};
}

sub strip_diacritics {
  my $txt = shift // return '';
  my $decomposed = NFKD $txt;
  $decomposed =~ s/\p{NonspacingMark}//gr;
}

sub numerically { $a <=> $b }

1;
