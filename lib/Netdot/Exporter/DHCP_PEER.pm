package Netdot::Exporter::DHCP_PEER;

use base 'Netdot::Exporter';

use warnings;
use strict;
use Data::Dumper;

use Git::Repository;
my $logger = Netdot->log->get_logger('Netdot::Exporter');

=head1 NAME

Netdot::Exporter::DHCP_PEER - Read relevant info from Netdot and build ISC DHCPD config file

=head1 SYNOPSIS

    my $dhcpd = Netdot::Exporter->new(type=>'DHCP_PEER');
    $dhcpd->generate_configs()

=head1 CLASS METHODS
=cut

############################################################################

=head2 new - Class constructor

  Arguments:
    None
  Returns:
    Netdot::Exporter::DHCPD object
  Examples:
    my $bind = Netdot::Exporter->new(type=>'DHCPD');
=cut

sub new{
    my ($class, %argv) = @_;
    my $self = {
                dir_export  => '/usr/local/netdot/export/dhcp.git'
                };

    bless $self, $class;
    return $self;
}

############################################################################

=head2 generate_configs - Generate config file for DHCPD

  Arguments:
    Hash with the following keys:
      peergroups - Global scope names (optional)
  Returns:
    True if successful
  Examples:
    $dhcpd->generate_configs();
=cut

sub generate_configs {
    my ($self, %argv) = @_;
    
    my $wdir = '/usr/local/netdot/export/peers';
    my $gitdir = '/usr/local/netdot/export/dhcp.git';
    
    my $git = Git::Repository->new( work_tree => $self->{dir_export} );
    
    my @pg;
    
    # yield all PG's when none given
    if ( !defined $argv{peergroups}) {
        @pg = DhcpPeer->retrieve_all()
    } else {
        foreach my $pg_name ( @{$argv{peergroups}}  ){
            if ( my $pg = DchpPeer->search( name=>$pg_name ) ){
                push @pg, $pg;
            } else {
                $self->throw_user("Peer Group $pg_name not found");
            }
        }
    }
    
    foreach my $pg ( @pg ) {
        
        my ($primary, $secondary);
        
        $self->throw_user("Primary Peer $pg->name not set") if ! $pg->primary_peer;
        
        $git->run( checkout => 'master' );
        $git->run( clean => '-f' );
        
        $git->run(
            add => $self->generate_file( primary => 1, pg => $pg)
        );
        if ($pg->secondary_peer) {
            $git->run(
                add => $self->generate_file( pg => $pg)
            );
        }
        
        
        $git->run(commit => "-m", "Netdot DHCP Commit ". localtime(time));
    };
    
}

sub generate_file(){
    my ($self, %argv) = @_;
    
    my $name;
    
    if ( $argv{primary}) {
        $name = $argv{pg}->primary_peer->get_label;
    } else {
        $name = $argv{pg}->secondary_peer->get_label;   
    }
    
    my $file = $self->{dir_export} . '/' . $name . '.conf';
    my $fh = Netdot::Exporter->open_and_lock( $file );
    print $fh $argv{pg}->generate_config(primary => $argv{primary});
    $fh->close;
    return $file;
}

=head1 AUTHOR

Carlos Vicente, C<< <cvicente at ns.uoregon.edu> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 University of Oregon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

#Be sure to return 1
1;
