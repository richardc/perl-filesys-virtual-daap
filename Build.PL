use strict;
use Module::Build;
Module::Build->new(
    module_name => 'Filesys::Virtual::DAAP',
    license     => 'perl',
    requires    => {
        'perl' => 5.006,
        'Class::Accessor'  => 0,
        'Filesys::Virtual' => 0,
        'Net::DAAP::Client::Auth' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
