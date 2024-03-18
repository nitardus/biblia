#! /usr/bin/perl
use strict;
use warnings;
use v5.16;
use utf8;
use open qw(:std :encoding(UTF-8));

=head1 Import csv bibles from www.biblesupersearch.com

This is a simple script to convert csv files of the Bible SuperSearch
website to bible's tsv format. To use it, we first create an index
file holding all the book names of this bible:

   perl BibleSuperSearch_csv2tsv.pl bible.csv > ABBREVFILE

We then have to edit this file and furnish every book title with an
abbreviation fitting the other bibles. For this, please have a look at the
make_abbrev.pl documentation. The file must have the following format:

Song of Solomon  	SSol

The separator should be a TAB character or at least three spaces.

Then, we can convert the csv file using the following command

   perl BibleSuperSearch_csv2tsv.pl ABBREVFILE bible.csv > bible.tsv

=cut

# Generating abbreviation file

if    (@ARGV == 1) {
  my $Lib_nr = 0;
  while (<>) {
    next unless /^\d/;
    chomp;
    my (undef, $lib, $lib_nr) = split ',';
    if ($Lib_nr != $lib_nr) {
      $Lib_nr = $lib_nr;
      say $lib_nr, "\t", $lib =~ tr/"//dr;
    }
  }
}
# converting to tsv file
elsif (@ARGV == 2) {
  my $abbrev_file = shift @ARGV;
  my %abbrevs;
  my %processed;
  open my $fh, '<', $abbrev_file or die "Cannot open $abbrev_file: $!\n";
  while (<$fh>) {
    chomp;
    my ($key, $name, $abbrev) = split /\t+|\s{3,}/;
    not $key    and die "No name defined for $key!\n";
    not $abbrev and die "No abbreviation defined for $name ($key)!\n";
    exists $processed{$abbrev} and die "Duplicate abbreviation $abbrev for $processed{$abbrev} and $name!\n";
    $processed{$abbrev} = $name;
    $abbrevs{$key} = [$name, $abbrev];
  }
  close $fh;

  while (<>) {
    next unless /^\d/;
    chomp;
    my ($num, $lib, $lib_nr, $cap, $vers, $txt) = split ',', $_, 6;
    $lib       = $abbrevs{$lib_nr}[0];
    my $abbrev = $abbrevs{$lib_nr}[1];
    $txt =~ tr/"//d;
    print "$lib\t$abbrev\t$lib_nr\t$cap\t$vers\t$txt\n";
  }
}
else { die "Error: check the documentation!\n" }
