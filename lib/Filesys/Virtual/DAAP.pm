package Filesys::Virtual::DAAP;
use strict;
use warnings;
use Filesys::Virtual::Plain ();
use base qw( Filesys::Virtual Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( cwd root_path home_path host ));
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
