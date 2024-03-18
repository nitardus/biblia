#! /usr/bin/perl
use strict;
use warnings;
use v5.16;
use utf8;
use open qw(:std :encoding(UTF-8));

=head1 MAKE ABBREV
Change the abbreviations of your bible files

This is a simple script that reads the abbreviations of a bible file
and dumps it to STDOUT (please redirect to an abbreviation file):

   perl make_abbrev.pl bible.tsv > ABBREVFILE

You can then edit this file an furnish it with another abbreviation: The file must have the following format:

Song of Solomon  	SSol

The separator should be a TAB character or at least three spaces.

You can then update your bible by executing the following commands

   perl make_abbrev.pl ABBREVFILE bible.tsv > bible_corrected.tsv
   mv bible_corrected.tsv bible.tsv

Do not overwrite the file directly! Doing so will give you an empty file.
Please make also sure to delete all old index files before you continue to use that bible:

   rm bible.idx

=cut

# Generating abbreviation file

if (@ARGV == 1) {
  my $No = 0;
  while (<>) {
    chomp;
    my ($name, $abbrev, $no, $cap, $vers, $txt) = split "\t";
    if ($No != $no) {
      $No = $no;
      say "$no\t$name\t$abbrev";
    }
  }
}
# converting to tsv file
elsif (@ARGV == 2) {
  my $abbrev_file = shift @ARGV;
  my %abbrevs;
  open my $fh, '<', $abbrev_file or die "Cannot open $abbrev_file: $!\n";
  while (<$fh>) {
    chomp;
    my ($key, $name, $abbrev) = split /\t+|\s{3,}/;
    $abbrevs{$key} = [$name, $abbrev];
  }
  close $fh;

  while (<>) {
    chomp;
    my ($name, $abbrev, $no, $cap, $vers, $txt) = split "\t";
    $name   = $abbrevs{$no}[0];
    $abbrev = $abbrevs{$no}[1];
    print "$name\t$abbrev\t$no\t$cap\t$vers\t$txt\n";
  }
}
else { die "Error: check the documentation!\n" }
