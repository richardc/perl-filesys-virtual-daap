#!/usr/bin/perl -w
use Test::More tests => 10;
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

is_deeply( [ $fs->list("/artists/Crysler/Unknown album/Games - mastered.mp3") ],
           [ "Games - mastered.mp3" ],
           "found Crysler/Unknown album/Games - mastered.mp3" );

is_deeply( [ $fs->list("/artists/Crysler/Unknown album/The sun has got his hat on.mp3") ],
           [ ],
           "did not find Crysler/Unknown album/The sun has got his hat on.mp3" );

is_deeply( [ $fs->list("/artists/Superpop/Unknown album/one.mp3") ],
           [ ],
           "did not find Superpop/Unknown album/one.mp3" );

is( $fs->size("/artists/Crysler/Unknown album/Games - mastered.mp3"), 3436916,
    "size of Crysler/Unknown album/Games - mastered.mp3" );

ok( my $fh = $fs->open_read("/artists/Crysler/Unknown album/Games - mastered.mp3"),
    "open Crysler/Unknown album/Games - mastered.mp3" );

if (eval { require File::Type; 1 }) {
    local $/;
    my $data = <$fh>;
    is( File::Type->new->checktype_contents( $data ), 'audio/mp3',
        "mime looks ok"  );
}
else {
    ok(1, "no File::Type, skipped");
}

ok( $fs->close_read( $fh ), "closed fh" );
