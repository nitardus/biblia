#! /usr/bin/perl
use v5.16;
use strict; use warnings;
use utf8;
use open qw( :std :encoding(UTF-8) );
use Term::ReadKey;
use Unicode::Collate;
our $Collator = Unicode::Collate->new
  (normalization => undef, level => 1);
use FindBin qw($Bin);
use File::Spec;
use lib File::Spec->catdir($Bin, '..', 'lib');
use Biblia;
use Scriba;

my ($terminal_width, $terminal_height) = GetTerminalSize();
my $lines = $ENV{BIBLIA_LINES} ? $ENV{BIBLIA_LINES} : $terminal_height -= 4;

# Parse command line arguments
my @editiones;
my @lectiones;
my $liber  = my $locus  = '';
my $mode  = -t STDIN && -t STDOUT ? 'i' : 'p';
parse_argv();

# Get the text into the buffer
for my $editio (@editiones) {
  my $biblia = Biblia->tolle(editio => $editio);
  die "You must specify a book!\n" unless $liber;
  push @lectiones, $biblia->lege($liber, $locus);
}

# Format the text
my $scriba = Scriba->accede();
$scriba->audi(@lectiones);

# Main loop
if    ($mode eq 'p') { $scriba->exscribe() }
elsif ($mode eq 'i') {
  ReadMode 3;
  my $k = " ";
  while (1) {
    if    ($k eq " ")  { print $scriba->exscribe($lines) // last }
    elsif ($k eq "\n") { print $scriba->exscribe(1) // last }
    elsif ($k eq "/")  { search("/") }
    elsif ($k eq "?")  { search("?") }
    elsif ($k eq "n")  { set_lines() }
    elsif ($k eq "q")  { exit 0 }
    last if $scriba->{finis};
    $k = ReadKey 0;
  }
}
else { die "Mode not set!\n" }

END { ReadMode 0 }

#----------------------------------------------------------------
### Function definitions
#----------------------------------------------------------------

sub print_help {

  print <<EOT;
USAGE: kjv [flags] [reference...] [editions...]

Flags;
  -A num  show num verses of context after matching verses [not implemented]
  -B num  show num verses of context before matching verses [not implemented]
  -l      list books
  -h      show help

Reference:
    <Book>
        Individual book
    <Book>:<Chapter>
        Individual chapter of a book
    <Book>:<Chapter>:<Verse>
        Individual verse(s) of a specific chapter of a book
    <Book>:<Chapter>-<Chapter>
        Range of chapters in a book
    <Book>:<Chapter>:<Verse>-<Verse>
        Range of verses in a book chapter
    <Book>:<Chapter>:<Verse>-<Chapter>:<Verse>
        Range of chapters and verses in a book

    /<Search> [not implemented]
        All verses that match a pattern
    <Book>/<Search>
        All verses in a book that match a pattern
    <Book>:<Chapter>/<Search>
        All verses in a chapter of a book that match a pattern;
EOT
}

sub parse_argv {
  unless (@ARGV) { print_help(); exit 0 }
  while  (@ARGV) {
    local $_ = shift @ARGV;
    if    (/^-[hlip]{2,}/) { die "Command line arguments $_ cannot be combined!\n" }
    elsif (s/^-h//)                 { print_help(); exit 0 }
    elsif (s/^-l//)                 { list_books(@ARGV); exit 0  }
    elsif (s/^-i//)                 { $mode = 'i' }
    elsif (s/^-p//)                 { $mode = 'p' }
    elsif (!$liber)                 { $liber   = $_ }
    elsif (!$locus and /^[-:\d]+$/) { $locus   = $_ }
    elsif (/^\w+$/)                 { push @editiones, $_ }
    else  { die "Unknown command: $_\n" }
  }
  @editiones = qw/grb/ unless @editiones;
}

sub list_books {
  my @editiones = @_ ? @_ : qw(grb);
  my @lists;
  for my $editio (@editiones) {
    my $biblia = Biblia->tolle(editio => $editio);
    my @list  = $biblia->enumera();
    my @abbrevs_list = map { $_->[0] } @list;
    my @names_list   = map { $_->[1] } @list;
    push @lists, [ \@abbrevs_list, \@names_list ]
  }
  my (@abbrev, @name);

  my $format =
    "format STDOUT_TOP =\n".
    "-" x $terminal_width  . "\n".
    ("@" . "|" x (($terminal_width / @lists) - 1) . " ") x @lists . "\n";
  $format .= join ', ', map "\$editiones[$_]", 0..$#editiones;
  $format .= "\n".
    "-" x $terminal_width  . "\n".
    ".\n\n";
  $format .=
    "format STDOUT =\n".
    ("^"."<" x 7 . ' ' . "^"."<" x (($terminal_width / @editiones) - 10) . " ") x @editiones.
    " ~~\n";
  $format .= join ', ',
    map "\$abbrev[$_], \$name[$_]", 0..$#editiones;
  $format .= "\n.\n";
  $format .= "$= = 50000;\n";

  eval $format;
  while (1) {
    @abbrev = @name = ();
    for my $list (@lists) {
      my $abbrev = shift @{ $list->[0] } || '';
      my $name   = shift @{ $list->[1] } || '';
      push @abbrev, $abbrev;
      push @name, $name;
    }
    last unless grep $_, @abbrev;
    write;
  }
}

my $quaestio = '';
sub search {
  my $dir   = shift;
  ReadMode 1;
  print $dir;
  my $input = <STDIN>;
  chomp $input;
  $input =~ s/^\s+(.*)\s+$/$1/;
  $quaestio = $input if $input;
  say STDERR $quaestio;
  ReadMode 3;
  print $scriba->quaere($liber, $dir, $quaestio);
}

sub set_lines {
  print "n: ";
  ReadMode 1;
  chomp( my $inp = <STDIN>);
  $inp =~ s/\s//g;
  if ($inp and $inp =~ /^\d+$/) { $lines = $inp }
  else { warn "Please enter a valid numeric value" }
  ReadMode 3;
}
