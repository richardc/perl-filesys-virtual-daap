package Filesys::Virtual::DAAP;
use strict;
use warnings;
use Net::DAAP::Client::Auth;
use Filesys::Virtual::Plain ();
use Scalar::Util qw( blessed );
use base qw( Filesys::Virtual Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( cwd root_path home_path host _client _vfs ));
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
    $self->_client( Net::DAAP::Client::Auth->new(
        SERVER_HOST => $self->host,
       ) );
    $self->_client->{DEBUG} = 0; # SHUT UP
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

sub list {
    my $self = shift;
    my $path = $self->_resolve_path( shift );
    my (undef, @chunks) = split m{/}, $path;
    my $walk = $self->_vfs;
    $walk = $walk->{$_} for @chunks;

    return blessed $walk ? $walk->filename : keys %{ $walk };
}


package Filesys::Virtual::DAAP::Song;
sub filename {
    my $self = shift;
    return $self->{'dmap.itemname'} . "." . $self->{'daap.songformat'};
}

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
