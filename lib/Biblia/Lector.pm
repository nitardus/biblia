package Biblia::Lector;

use v5.16;
use strict;
use warnings;
use Encode qw(encode decode);
use File::Spec;
use Term::ReadKey;
use utf8;
use open qw(:std :encoding(UTF-8));

my %defaults =
  ( editio  => 'grb',
    path    => '',
    suffix  => 'tsv'
  );

sub tolle {
  my $proto = shift;
  my $type = ref($proto) || $proto;
  my $self = {};
  bless $self, $type;
  my %args;  my %passed = @_;
  $args{ validate($_) } = $passed{$_} for keys %passed;
  %{ $self } = ( %{ $self }, %defaults, %args );
  # %{ $self } = ( %{ $self }, %defaults, $self->read_configuration, %args );
  $self->get_path();
  $self->read_index();
  return $self;
}

sub lege {
  my $self  = shift;
  my $liber = shift || 0;
  if ($liber) {
    die "Unknown reference $liber"
      unless exists $self->{index}{$liber};
    my $caput_ultimum = maximum( grep /^\d+/, keys %{ $self->{index}{$liber} } );

    my $locus = shift;
    my ($unde, $quo);
    if    (ref $locus) {
      $unde  = $locus || [0, 0];
      $quo   = shift  || $unde;
    }
    elsif (not $locus) { $unde = $quo = [0,0] }
    elsif ($locus =~ /^[-:\d]+$/) {
      ($unde, $quo) = parse_locus($locus)
    }
    else { die "Invalid locus $locus!" }

    my $caput_unde  = $unde->[0];
    my $versus_unde = $unde->[1] || 0;
    my $caput_quo   = $quo->[0];
    my $versus_quo  = $quo->[1] || 0;
    die "Invalid reference!"
      unless $caput_unde < $caput_quo
      or     $caput_unde == $caput_quo and $versus_unde <= $versus_quo;
    die "Last chapter of $liber is $caput_ultimum"
      if $caput_quo > $caput_ultimum;

    open my $fh, '<', $self->{file} or die "Cannot open $self->{file}: $!";

    my $start = ($caput_unde == 0)
      ? $self->{index}{$liber}{start}
      : $self->{index}{$liber}{$caput_unde}{start};
    my $end   = ($caput_quo == 0)
      ? $self->{index}{$liber}{end}
      : $self->{index}{$liber}{$caput_quo}{end};
    seek $fh, $start, 0;

    while (<$fh>) {
      chomp;
      my ($name, $abbrev, $no, $cap, $vers, $txt) = split "\t";
      last if tell $fh > $end;
      next if $cap == $caput_unde and $versus_unde and $vers < $versus_unde;
      next if $cap == $caput_quo  and $versus_quo  and $vers > $versus_quo;
      $self->{lectio}{$abbrev}{$cap}{$vers} = $txt;
      push @{ $self->{lectio}{$abbrev}{-1} }, [ $cap, $vers ];
      $self->{lectio}{$abbrev}{-2} = $name;
    }
    close $fh;
  }
  else {
    open my $fh, '<', $self->{file} or die "Cannot open $self->{file}: $!";
    my $lib = '';
    while (<$fh>) {
      chomp;
      my ($name, $abbrev, $no, $cap, $vers, $txt) = split "\t";
      $self->{lectio}{$abbrev}{$cap}{$vers} = $txt;
      push @{ $self->{lectio}{$abbrev}{-1} }, [ $cap, $vers ];
      if ($lib ne $abbrev) {
	$lib = $abbrev;
	push @{ $self->{lectio}{-1} }, $lib;
	STDERR $self->{lectio}{$abbrev}{-2} = $name;
      }
    }
  }
  return $self->{lectio};
}

sub enumera {
  my $self = shift;
  my @index;
  for my $key (sort { $self->{index}{$a}{start} <=> $self->{index}{$b}{start} }
	       keys %{ $self->{index} } ) {
    push @index, [$key, $self->{index}{$key}{name}];
  }
  return @index;
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

sub get_path {
  my $self  = shift;
  my $root  = $self->{path} if $self->{path};
  my @paths = (
	       File::Spec->catdir($ENV{HOME}, '.config', 'Biblia'),
	       File::Spec->catdir($ENV{HOME}, '.Biblia')
	      );
  unshift @paths, File::Spec->catdir($root, 'data') if $root;
  unshift @paths, $ENV{BIBLIA_PATH} if $ENV{BIBLIA_PATH};
  do { return if $self->validate_path() }
    while ( $self->{path} = shift @paths );
  say STDERR "Cannot find $self->{editio}: Please enter the path:";
  chomp( $self->{path} = <STDIN> );
  exit unless $self->{path};
  return if $self->validate_path();
  die "Invalid path $self->{path}!\n";
}

sub validate_path {
  my $self = shift;
  my $path = $self->{path} || return 0;
  my $filename = "$self->{editio}.$self->{suffix}";
  my $file = File::Spec->catfile($path, $filename);
  return (-d $path && -e $file) ? 1 : 0;
}

sub parse_locus {
  my $locus = shift;
  my ($unde, $quo) = split '-', $locus;
  my ($lib_unde, $cap_unde) = ($unde =~ /:/) ? split( ':', $unde ) : ($unde,0);
  $unde = [$lib_unde, $cap_unde];

  if ($quo) {
    my ($lib_quo, $cap_quo) =
      ($quo =~ /:/) ? split( ':', $quo) :
      ($cap_unde)   ? ($lib_unde, $quo)
                    : ($quo,      0);
    $quo = [$lib_quo,  $cap_quo];
  }
  else { $quo = $unde }
  return $unde, $quo;
}

sub read_index {
  my $self = shift;
  $self->{file} =
    File::Spec->catfile($self->{path}, "$self->{editio}.$self->{suffix}");
  die "No data found for bible $self->{editio}\n"
    unless -e $self->{file};
  $self->{indexfile} = File::Spec->catfile($self->{path}, "$self->{editio}.idx");
  if ( -f $self->{indexfile} ) {
    open my $fh, '<', $self->{indexfile}
      or die "Unable to load indexfile for $self->{editio}: $!\n";
    my %index;
    my $lib = '';
    while (<$fh>) {
      chomp;
      if    (/^\S/) {
	(my $name, $lib, my $start, my $end) = split /\t/;
	$index{$lib}{start} = $start;
	$index{$lib}{end}   = $end;
	$index{$lib}{name}  = $name;
      }
      elsif (/^\t/) {
	die unless $lib;
	my (undef, $cap, $start, $end) = split /\t/;
	$index{$lib}{$cap}{start} = $start;
	$index{$lib}{$cap}{end}   = $end;
      }
      else { die "Error in indexfile $self->{indexfile}" }
    }
     $self->{index} = \%index;
  }
  else {
    $self->make_index;
  }
}

sub make_index {
  my $self = shift;
  use bytes;
  my %index;
  my $liber = ''; my $caput = my $versus = 0;
  open my $fh, '<', $self->{file}
    or die "Unable to load file for $self->{editio}: $!\n";
  while (<$fh>) {
    my ($name, $abbrev, $no, $cap) = split "\t";
    if ($liber ne $abbrev) {
      if (defined $liber and $liber ne '') {
	$index{$liber}{end} = $index{$liber}{$caput}{end} = tell($fh) - length($_);
      }
      $liber = $abbrev;
      $caput = $cap;
      $index{$liber}{name}   = $name;
      $index{$liber}{no}     = $no;
      $index{$liber}{abbrev} = $abbrev;
      $index{$liber}{start} = $index{$liber}{$caput}{start} = tell($fh) - length($_);
    }
    elsif ($caput ne $cap) {
      if (defined $caput and $caput ne '') {
	$index{$liber}{$caput}{end} = tell($fh) - length($_);
      }
      $caput = $cap;
      $index{$liber}{$caput}{start} = tell($fh) - length($_);
    }
  }
  close $fh;
  $index{$liber}{end} = $index{$liber}{$caput}{end} = -s $self->{file};

  $self->{index} = \%index;
  $self->write_index() or warn "unable to write index to file: $!"
}

sub write_index {
  my $self = shift;
  open my $fh, '>', $self->{indexfile}
    or die "Unable to write to index file for $self->{editio}: $!\n";
  for my $key ( sort { $self->{index}{$a}{start} <=> $self->{index}{$b}{start} }
		keys %{ $self->{index} } ) {
    my $lib = $self->{index}{$key};
    say {$fh} "$lib->{name}\t$key\t$lib->{start}\t$lib->{end}";
    for my $cap (sort { $lib->{$a}{start} <=> $lib->{$b}{start} }
		 grep /^\d+$/, keys %$lib) {
      # die "\t$cap\t$lib->{$cap}{start}\t$lib->{$cap}{end}"
      # 	unless defined $cap and defined $lib->{$cap}{start} and defined $lib->{$cap}{end};
      say {$fh} "\t$cap\t$lib->{$cap}{start}\t$lib->{$cap}{end}";
    }
  }
  close $fh;
}

sub maximum {
  my $max = 0;
  $max < $_ and $max = $_ for @_;
  return $max;
}

1;
