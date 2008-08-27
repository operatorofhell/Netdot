#!/usr/bin/perl

# Generate grep'able circuit info files from Netdot
#
#
use strict;
use lib "<<Make:LIB>>";
use Netdot::Model;
use Data::Dumper;
use Getopt::Long;

use vars qw( %self $USAGE @circuits );

&set_defaults();

my $USAGE = <<EOF;
usage: $0 --dir <DIR> --out <FILE>

    --dir             <path> Path to configuration file
    --out             <name> Configuration file name (default: $self{out})
    --debug           Print debugging output
    --help            Display this message

EOF

&setup();
&gather_data();
&build_configs();


##################################################
sub set_defaults {
    %self = ( 
	      dir             => '',
	      out             => 'circuits.txt',
	      help            => 0,
	      debug           => 0, 
	      );
}

##################################################
sub setup{
    
    my $result = GetOptions( 
			     "dir=s"            => \$self{dir},
			     "out=s"            => \$self{out},
			     "debug"            => \$self{debug},
			     "h"                => \$self{help},
			     "help"             => \$self{help},
			     );
    
    if( ! $result || $self{help} ) {
	print $USAGE;
	exit 0;
    }

    unless ( $self{dir} && $self{out} ) {
	print "ERROR: Missing required arguments\n";
	die $USAGE;
    }
}

##################################################
sub gather_data{
    
    unless ( @circuits = Circuit->retrieve_all() ){
	die "No circuits found in db\n";
    }
    
}

##################################################
sub build_configs{

    my $file = "$self{dir}/$self{out}";
    open (FILE, ">$file")
	or die "Couldn't open $file: $!\n";
    select (FILE);

    print "            ****        THIS FILE WAS GENERATED FROM A DATABASE         ****\n";
    print "            ****           ANY CHANGES YOU MAKE WILL BE LOST            ****\n";
    
    @circuits = sort { $a->cid cmp $b->cid } @circuits;
    foreach my $c (@circuits){
            my %contacts;
	    my @comments = $c->info;
	    my $prefix = $c->cid . ":" ;
	    $prefix .= " " . $c->connectionid->name if ($c->connectionid);
	    print $prefix, ": Type: ", $c->type->name, "\n" if ($c->type);
	    print $prefix, ": Speed: ", $c->speed, "\n" if ($c->speed);
	    print $prefix, ": Provider: ", $c->vendor->name, "\n" if ($c->vendor);
	    print $prefix, ": DLCI: ", $c->dlci, "\n" if ($c->dlci);
	    print $prefix, ": Near Interface: ", $c->nearend->name, ",", $c->nearend->device->name->name, "\n" 
	        if ($c->nearend && $c->nearend->device && $c->nearend->device->name);
	    print $prefix, ": Far Interface: ", $c->farend->name, ",", $c->farend->device->name->name, "\n" 
	        if ($c->farend && $c->farend->device && $c->farend->device->name);
	    if ($c->connectionid){
		print $prefix, ": Entity: ", $c->connectionid->entity->name, "\n" if ($c->connectionid->entity);
		if ( (my $n = $c->connectionid->nearend) != 0){
		   print $prefix, ": Origin: ", $n->name, "\n"; 
		   print $prefix, ": Origin: ", $n->street1, "\n"; 
		   print $prefix, ": Origin: ", $n->city, "\n"; 
		}
		map { $contacts{$_->id} = $_ } $c->connectionid->entity->contactlist->contacts 
		     if ($c->connectionid && $c->connectionid->entity && $c->connectionid->entity->contactlist);
		if ((my $f = $c->connectionid->farend) != 0){
		   map { $contacts{$_->id} = $_ } $f->contactlist->contacts if ($f->contactlist);
		   print $prefix, ": Destination: ", $f->name, "\n"; 
		   print $prefix, ": Destination: ", $f->street1, "\n"; 
		   print $prefix, ": Destination: ", $f->city, "\n"; 
		}
	    }
	    foreach my $contact ( sort { $a->person->lastname cmp $b->person->lastname } 
	    	                  map { $contacts{$_} } keys %contacts ){
		my $person = $contact->person;
		my $pr = $prefix . ": Contacts : " . $person->firstname . " " . $person->lastname;
	    	print $pr, ": Role: ", $contact->contacttype->name, "\n" if ($contact->contacttype);
	    	print $pr, ": Position: ", $person->position, "\n" if ($person->position);
	    	print $pr, ": Office: ", $person->office, "\n" if ($person->office);
	    	print $pr, ": Email: <", $person->email, ">\n" if ($person->email);
	    	print $pr, ": Cell: ", $person->cell, "\n" if ($person->cell);
	    	print $pr, ": Pager: ", $person->pager, "\n" if ($person->pager);
	    	print $pr, ": Email-Pager: ", $person->emailpager, "\n" if ($person->emailpager);
	   }
	   foreach my $l (@comments){
              print $prefix, " Comments: ", $l, "\n";
	   }
	   print "\n";
    }

    close (FILE) or warn "$file did not close nicely\n";
}
