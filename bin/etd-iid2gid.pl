#!/usr/bin/env perl

# etd-iid2gid.pl - given an item id, output a generic file id

# Eric Lease Morgan <emorgan@nd.edu>
# March 12, 2019 - first investigations


# configure
use constant SOLR     => 'https://solr41prod.library.nd.edu:8443/solr/curate';
use constant QUERY    => 'identification_identity_mime_type_tesim:application/pdf AND is_part_of_ssim:info:fedora/';
use constant HOST     => 'localhost';
use constant PORT     => 7890;
use constant PROTOCOL => 'tcp';

# require
use IO::Socket::INET;
use strict;
use WebService::Solr;

# initialize
my $socket = IO::Socket::INET->new( LocalHost => HOST, LocalPort => PORT, Proto => PROTOCOL, Listen => 1, Reuse => 1 ) or die "Can't create socket ($!)\n";
my $solr   = WebService::Solr->new( SOLR );

# listen, forever
while ( my $client = $socket->accept() ) {

	# get the input, build the query, and search
	my $iid      = <$client>;	
	my $query    = QUERY . $iid;
	my $response = $solr->search( $query );
	
	# get the (first) document, and output the generic file id
	for my $doc ( $response->docs ) {
	
		print $client $doc->value_for( 'id' );
		last;
	
	}

}