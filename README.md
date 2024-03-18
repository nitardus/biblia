BIBLIA - Read the Bible in the command line
===========================================

This project is a reimplementation of Luke Smith's command line bibles
[grb](https://github.com/lukesmithxyz/grb), [vul](https://github.com/LukeSmithxyz/vul), and [kjv](https://github.com/LukeSmithxyz/kjv), which in turn extend the original
[kjv](https://github.com/layeh/kjv).

Install
-------

As this program is a perl distribution written with Module::Build, it installs by executing

	perl Build.PL
	./Build
	./Build test
	./Build install
	./Build clean

Usage
-----

See the usage help notice:

	biblia -h
	
	
Update Book Names and Abbreviations
-----------------------------------

This distribution includes a script which facilitates changing the
book names and abbreviations of the bible files used by biblia. First,
you have to dump an abbreviation file containing all the current book
names and abbreviations:

	utils/make_abbrev.pl data/bible.tsv > some/path/bible.abbrev
	
Then you can edit this file to your hearts content and finally make an updated bible file with new book names

	utils/make_abbrev.pl some/path/bible.abbrev data/bible.tsv > data/new_bible.tsv
	
You then have to either rebuild biblia or copy the new bible to your
Bible directory (~/.Biblia or ~/.config/Biblia). But be warned: Unless
all the bible files use the same abbreviations, you cannot use them in
parallel to view the same book in different editions simultaneously.
In the future, there will be an .alias file, where you can specify
your own abbreviations and leave biblia's internal abbreviations intact.

Import New Bible Editions
-------------------------

You can import bibles form the internet, too, provided their format
can be changed to biblia's .tsv format. At the moment, there is a
convenience script that converts the .csv format of the
https://www.biblesupersearch.com/ site to biblia's tsv format. You first have to make an abbreviation file

	utils/BibleSuperSearch_csv2tsv.pl some/path/bible.csv > some/path/bible.abbrev
	
You then have to edit this file and insert the right abbreviations. The abbreviation must be separated from the name by a tab or at least three spaces:

    Genesis	          Ge

After finishing this, you then can write the bible.tsv

	utils/BibleSuperSearch_csv2tsv.pl some/path/bible.abbrev some/path/bible.csv > data/bible.tsv

LIMITATIONS
-----------

Currently, you have to specify a single book of the bible, which will
be loaded into biblia's buffer: You cannot load multiple books, or
even the whole bible. In the future, there will be a way around this.

You cannot search for a term in the command line: Searching is only
possible in interactive mode.

BUGS
----
In some terminals, bibles in languages that write right to left (e.g.
Hebrew) there are some issues with the alignment of some characters.

If you find some other bugs (there have to be plenty!), plese report
them so they can get fixed!

LICENSE AND COPYRIGHT
---------------------

This software is Copyright (c) 2024 by Michael Neidhart.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007
  
Of the included data files data/vul.tsv and data/kjv.tsv are both
public domain; the SBL Greek New Testament translation/edition has a
permissive license for non-commercial uses. See it
[here](https://sblgnt.com/license/).

