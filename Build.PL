use v5.14;
use strict;
use warnings;
use Module::Build;
use File::Spec;
Module::Build->VERSION('0.4004');

die "No home directory specified! Please set it: export HOME='/path/to/dir'!\n"
  unless exists $ENV{HOME} and -d $ENV{HOME};


my $data_path = ( -d File::Spec->catdir($ENV{HOME}, '.config') )
  ? File::Spec->catdir($ENV{HOME}, '.config', 'Biblia')
  : File::Spec->catdir($ENV{HOME}, '.Biblia');
say STDERR "Creating directory for bibles to install: $data_path";
File::Path::mkpath($data_path, 0, oct(777));

my $builder = Module::Build->new
  (
   module_name        => 'Biblia',
   license            => 'GPL_3',
   dist_author        => q{Michael Neidhart <mayhoth@gmail.com>},
   dist_version_from  => 'lib/Biblia.pm',
   release_status     => 'stable',
   create_license     => 1,
   script_files       => 'script/biblia',
   tsv_files          => { 'data/grb.tsv' => 'data/grb.tsv',
			   'data/vul.tsv' => 'data/vul.tsv',
			   'data/kjv.tsv' => 'data/kjv.tsv',
			 },
   install_path       => { data => $data_path },
   configure_requires => {
			  'Module::Build' => '0.4004',
			 },
   test_requires => {
		     'Test::More' => '0',
		    },
   requires => {
		'Encode'        => 0,
		'FindBin'       => 0,
		'File::Spec'    => 0,
		'Term::ReadKey' => 0,
	       },
   add_to_cleanup     => [ 'Biblia-*' ],
  );
$builder->add_build_element('tsv');
$builder->create_build_script();
