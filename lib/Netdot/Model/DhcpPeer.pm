package Netdot::Model::DhcpPeer;

use base 'Netdot::Model';
use warnings;
use strict;

my $logger = Netdot->log->get_logger('Netdot::Model::DHCP');

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