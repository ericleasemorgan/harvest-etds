#!/usr/bin/env perl

# etd-iid2gid.pl - given an item id, output a generic file id

# Eric Lease Morgan <emorgan@nd.edu>
# March 11, 2019 - first investigations


# configure
use constant SOLR  => 'https://solr41prod.library.nd.edu:8443/solr/curate';
use constant QUERY => 'is_part_of_ssim:info:fedora/';

# require
use strict;
use WebService::Solr;

# sanity check
my $id = $ARGV[ 0 ];
if ( ! $id ) { die "Usage: $0 <id>\n" }

# configure environment
binmode( STDOUT, ":utf8" );
binmode( STDERR, ":utf8" );
$| = 1;

# initialize
my $solr  = WebService::Solr->new( SOLR );

# build a query and do the search
my $response = $solr->search( QUERY . $id );

# initialize results and loop through each document
for my $doc ( $response->docs ) {
	
	# parse
	my $gid = $doc->value_for( 'id' );
	$gid =~ s/.*://g;
	print "$gid";
		
}

