#!/usr/bin/perl -w
use Test::More tests => 3;
use Filesys::Virtual::DAAP;

if (eval { require Test::Differences; 1 }) {
    no warnings 'redefine';
    *is_deeply = \&Test::Differences::eq_or_diff;
}

my $fs = Filesys::Virtual::DAAP->new({
    host      => 'localhost',
    cwd       => '/',
    root_path => '/',
    home_path => '/home',
});

is_deeply( [ $fs->list("/artists") ], [ "Crysler" ],
           "found Crysler" );
is_deeply( [ $fs->list("/artists/Crysler") ], [ "Unknown album" ],
           "found Crysler/Unknown album" );
is_deeply( [ sort $fs->list("/artists/Crysler/Unknown album") ],
           [ "Games - mastered.mp3",
             "Insomnia - mastered.mp3",
             "Your Voice - mastered.mp3" ],
           "found Crysler/Unknown album/*.mp3" );