package Biblia;

use v5.16;
use strict;
use warnings;
use Biblia::Lector;
use Biblia::Scriba;

=head1 NAME

Biblia - read the Holy Scripture in the command line

=head1 VERSION  Version 0.3

=cut

our $VERSION = 0.03;

=head1 SYNOPSIS

This module fives you access to various bible files in a special tsv
format. It searches for a specific portuob if text an returns it. It
should be uses together with the Scriba module, which formats the text
and returns it line by line.

It comes with three bibles included: The Greek SBL text {sbl}, the Latin Clementine Vulgate {vul} and zhe King James Version (sbl).

   use Biblia;
   use Scriba;

   $biblia = Biblia->tolle( editio => 'sbl' ) # default
   @list_of_books = $biblia->enumera();
   $lectio = $biblia->lege('Luke', '13:12');
   push @lectio, @lectones;

   my $scriba = Scriba->accede();
   $scriba->audi(@lectiones)
   $scriba->exscribe(5);
   $scriba->exscribe();

=head1 AUTHOR

Michael Neidhart, C<< <mayhoth at gmail.com> >>

=head1 BUGS

A lot, probably!

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
perldoc Biblia ...

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Michael Neidhart.

=cut

1;
