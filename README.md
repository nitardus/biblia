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

See the usage help

	biblia -h


LICENSE AND COPYRIGHT
---------------------

This software is Copyright (c) 2024 by Michael Neidhart.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007
  
Of the included data files data/vul.tsv and data/kjv.tsv are both
public domain; the SBL Greek New Testament translation/edition has a
permissive license for non-commercial uses. See it
[here](https://sblgnt.com/license/).

