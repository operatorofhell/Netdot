package Netdot::Model::DhcpPeer;

use base 'Netdot::Model';
use warnings;
use strict;

my $logger = Netdot->log->get_logger('Netdot::Model::DHCP');
############################################################################

=head2 insert - Insert a new ISC DHCP  Peer group 

    We override the insert method for extra functionality.

 Args: 
        name
        hba
        max_response_delay
        max_unacked_updates
        mclt
        load_balance_max_seconds
        port
        primary_peer                link to RR
        secondary_peer              link to RR
        split
        auto_partner_down
  Returns: 
    DhcpPeer object
  Examples:
    my $pg = DhcpPeer->insert({name=>'PG_TEST'});
    
=cut
sub insert {
    my ($class, $argv) = @_;
    $class->throw_fatal("Model::Zone::insert: Missing required arguments")
	unless ( $argv->{name} );
    
    my %state = (
        
        name                        => $argv->{name},
        primary_peer                => $argv->{primary_peer},
        secondary_peer              => $argv->{secondary_peer},
        hba                         => $argv->{hba},
        max_response_delay          => $argv->{max_response_delay}          ||$class->config->get('DEFAULT_DHCP_MAX_RESPONSE_DELAY'),
        max_unacked_updates         => $argv->{max_unacked_updates}         ||$class->config->get('DEFAULT_DHCP_MAX_UNACKED_UPDATES'),
        mclt                        => $argv->{mclt}                        ||$class->config->get('DEFAULT_DHCP_MCLT'),
        load_balance_max_seconds    => $argv->{load_balance_max_seconds}    ||$class->config->get('DEFAULT_DHCP_LOAD_BALANCE_MAX_SECONDS'),
        port                        => $argv->{port}                        ||$class->config->get('DEFAULT_DHCP_PORT'),
        split                       => $argv->{split}                       ||$class->config->get('DEFAULT_DHCP_SPLIT'),
        auto_partner_down           => $argv->{auto_partner_down}           ||$class->config->get('DEFAULT_DHCP_AUTO_PARTNER_DOWN'),

    );

	my $newpg = $class->SUPER::insert( \%state );
    
    return $newpg
}
############################################################################

=head2 generate_config -  Returns the config  (ISC DHCPD format)

  Args: 
    Hash with following keys:
  Returns: 
    Scalar
  Examples:
    $scope->generate_config( role => primary);

=cut

sub generate_config{
    my ($self, %argv) = @_;
    $self->isa_object_method('generate_config');
    my $class = ref($self);
    my $config;
    my $ei = '';
    my $ii = " " x 4;
    
    $config = $ei . sprintf("failover peer \"%s\" {\n", $self->name() );
    
    my ( $addr, $peeraddr);
    
    if ( $argv{primary} ) {     
        $config .= $ei . $ii . "primary;\n";
        $config .= $ei . $ii . "address "              . $self->primary_peer->a_records->next->ipblock->address() . ";\n";
        $config .= $ei . $ii . "peer address "         . $self->secondary_peer->a_records->next->ipblock->address() . ";\n";
        $config .= $ei . $ii . "split "                . $self->split. ";\n";
        $config .= $ei . $ii . "mclt "                 . $self->mclt . ";\n";
    } else {
        $config .= $ei . $ii . "secondary;\n";
        $config .= $ei . $ii . "address "              . $self->secondary_peer->a_records->next->ipblock->address() . ";\n";
        $config .= $ei . $ii . "peer address "         . $self->primary_peer->a_records->next->ipblock->address() . ";\n";
    }
    
    $config .= $ei . $ii . "port "                     . $self->port . ";\n";
    $config .= $ei . $ii . "peer port "                . $self->port . ";\n";
    $config .= $ei . $ii . "max-response-delay "       . $self->max_response_delay . ";\n";
    $config .= $ei . $ii . "max-unacked-updates "      . $self->max_unacked_updates . ";\n";
    $config .= $ei . $ii . "load balance max seconds " . $self->load_balance_max_seconds . ";\n";
    
    $config .= $ei . "}\n\n";
    
    return  $config;
}