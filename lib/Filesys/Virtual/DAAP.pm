package Filesys::Virtual::DAAP;
use strict;
use warnings;
use Net::DAAP::Client::Auth;
use Filesys::Virtual::Plain ();
use File::Temp qw( tempdir );
use IO::File;
use Scalar::Util qw( blessed );
use base qw( Filesys::Virtual Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( cwd root_path home_path host port _client _vfs _tmpdir ));
our $VERSION = '0.01';

=head1 NAME

Filesys::Virtual::DAAP - present a DAAP share as a VFS

=head1 SYNOPSIS

 use Filesys::Virtual::DAAP;
 my $fs = Filesys::Virtual::DAAP->new({
     host      => 'localhost',
     cwd       => '/',
     root_path => '/',
     home_path => '/home',
 });
 my @albums = $fs->list("/albums");


=head1 DESCRIPTION


=cut

# HACKY - mixin these from the ::Plain class, they only deal with the
# mapping of root_path, cwd, and home_path, so they should be safe
*_path_from_root = \&Filesys::Virtual::Plain::_path_from_root;
*_resolve_path   = \&Filesys::Virtual::Plain::_resolve_path;

sub new {
    my $ref = shift;
    my $self = $ref->SUPER::new(@_);
    $self->_tmpdir( tempdir( CLEANUP => 1 ) );

    $self->_client( Net::DAAP::Client::Auth->new(
        SERVER_HOST => $self->host,
       ) );
    $self->_client->{DEBUG} = 0; # SHUT UP
    $self->_client->{SERVER_PORT} = $self->port || 3689;
    $self->_client->connect;
    $self->_build_vfs;
    return $self;
}

    use YAML;

sub _build_vfs {
    my $self = shift;
    $self->_vfs( {} );
    for my $song (values %{ $self->_client->songs }) {
        bless $song, __PACKAGE__."::Song";
        $self->_vfs->{artists}{ $song->{'daap.songartist'} }
          { $song->{'daap.songalbum'} || "Unknown album" }
          { $song->filename } = $song;
    }
    #print Dump $self->_vfs;
}

sub _get_leaf {
    my $self = shift;
    my $path = $self->_resolve_path( shift );
    my (undef, @chunks) = split m{/}, $path;
    my $walk = $self->_vfs;
    $walk = $walk->{$_} for @chunks;
    return $walk;
}

sub list {
    my $self = shift;
    my $leaf = $self->_get_leaf( shift );
    return blessed $leaf ? $leaf->filename : qw( . .. ), keys %{ $leaf };
}

sub list_details {
    my $self = shift;
    my $leaf = $self->_get_leaf( shift );

    return blessed $leaf ? $self->_ls_file( $leaf->filename => $leaf ) :
      map { $self->_ls_file( $_ => $leaf->{$_} ) } qw( . .. ), sort keys %{ $leaf };
}

sub _ls_file {
    my $self = shift;
    my ($name, $leaf) = @_;
    if (blessed $leaf) {
#                       drwxr-xr-x  46 richardc  richardc  1564  5 May 10:03 Applications
        return sprintf "-r--r--r--   1 richardc  richardc %8s 7 May 12:41\t%s",
          $leaf->size, $leaf->filename;
    }
    else {
        return sprintf "drwxr-xr-x   3 richardc  richardc %8s 7 May 12:41\t%s",
          1024, $name;
    }
}

sub chdir {
    my $self = shift;
    my $to   = $self->_resolve_path( shift );
    my $leaf = $self->_get_leaf( $to );
    return undef unless ref $leaf eq 'HASH';
    return $self->cwd( $to );
}


# well if ::Plain can't be bothered, we can't be bothered either
sub modtime { return (0, "") }

sub stat {
    my $self = shift;
    my $leaf = $self->_get_leaf( shift );
    return unless $leaf;
    if (blessed $leaf) {
        # dev, ino, mode, nlink, uid, gid, rdev, size, atime, mtime, ctime, blksize, blocks
        return (0+$self, 0+$leaf, 0100444, 1, 0, 0, 0, $leaf->size,
                0, 0, 0, 1024, ($leaf->size / 1024) + 1);
    }
    else {
        return (0+$self, 0+$leaf, 042555, 1, 0, 0, 0, 1024,
                0, 0, 0, 1024, 1);
    }
}

sub size {
    my $self = shift;
    return ( $self->stat( shift ))[7];
}

sub test {
    my $self = shift;
    my $test = shift;
    my $leaf = $self->_get_leaf( shift );

    local $_ = $test;
    return 1  if /r/i;
    return '' if /w/i;
    return 1  if /x/i && !blessed $leaf;
    return '' if /x/i;
    return 1  if /o/i;

    return 1  if /e/;
    return '' if /z/;
    return $leaf->size if /s/ && blessed $leaf;
    return 1024 if /s/;

    return 1  if /f/ && blessed $leaf;
    return '' if /f/;
    return 1  if /d/ && !blessed $leaf;
    return '' if /[dpSbctugkT]/;
    return 1  if /B/;
    return 0  if /[MAC]/;
    die "Don't understand -$test";
}

# Don't touch our filez
sub chmod { 0 }
sub mkdir { 0 }
sub delete { 0 }
sub rmdir { 0 }

sub login { 1 }

sub open_read {
    my $self = shift;
    my $leaf = $self->_get_leaf( shift );
    $self->_client->save( $self->_tmpdir, $leaf->id );
    return IO::File->new( $self->_tmpdir . "/". $leaf->id . ".mp3" );
}

sub close_read {
    my $self = shift;
    my $fh = shift;
    close $fh;
    return 1;
}

sub open_write { return }
sub close_write { 0 }

package Filesys::Virtual::DAAP::Song;
sub id { $_[0]->{'dmap.itemid'} }

sub filename {
    my $self = shift;
    return $self->{'dmap.itemname'} . "." . $self->{'daap.songformat'};
}

sub size { $_[0]->{'daap.songsize'} }

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filesys::Virtual::DAAP>.


=head1 SEE ALSO


=cut

1;
