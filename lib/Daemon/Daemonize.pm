package Daemon::Daemonize;

use warnings;
use strict;

=head1 NAME

Daemon::Daemonize - A daemonizer

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';


=head1 SYNOPSIS

    use Daemon::Daemonize

    Daemon::Daemonize->launch_daemon( %options, sub {

        # Daemon code in here...

    } )

    # Do some non-daemon stuff here...

=cut

use POSIX;
use Carp;

sub _do_fork {
    my $class = shift;

    my $process = fork;
    die "Unable to fork" unless defined $process;
    if ( $process ) {
        # We're the parent
        exit( 0 );
    }

    return 0;
}

sub _shut_down_everything {
    my $class = shift;

    my $openmax = POSIX::sysconf( &POSIX::_SC_OPEN_MAX );
    $openmax = 64 if ! defined( $openmax ) || $openmax < 0;

    POSIX::close($_) foreach (0 .. $openmax - 1);
}

sub daemon {
    my $class = shift;
    my %given = @_;

    # Fork once to go into the background
    $class->_do_fork;

    # Create new session
    (POSIX::setsid)
        || confess "Cannot detach from controlling process";

    # Fork again to ensure that daemon never reacquires a control terminal
    $class->_do_fork;

    # Clear the file creation mask
    umask 0;

    # Change to the root so we don't intefere with unmount
    unless( $given{nochdir} ) {
        chdir '/';
    }

    unless( $given{noclose} ) {
        # Close any open file descriptors
        $class->_shut_down_everything;

        # Re-open  STDIN, STDOUT, STDERR to /dev/null
        open( STDIN,  "+>/dev/null" );
        open( STDOUT, "+>&STDIN" );
        open( STDERR, "+>&STDIN" );
    }

    return 1;
}

sub launch_daemon {
    my $class = shift;
    my $code = pop;
    my %given = @_;

    if ( fork ) { 
        # We're the parent, continue on...
    }
    else {
        # First daemonize
        $class->daemonize( %given );
        # Then launch into the code we've been given...
        $code->();
    }
}

sub daemonize {
    my $class = shift;
    my %given = @_;

    $class->daemon( %given );
}

=head1 SEE ALSO

L<MooseX::Daemonize>

L<Proc::Daemon>

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-daemon-daemonize at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Daemon-Daemonize>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Daemon::Daemonize


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Daemon-Daemonize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Daemon-Daemonize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Daemon-Daemonize>

=item * Search CPAN

L<http://search.cpan.org/dist/Daemon-Daemonize/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Daemon::Daemonize
