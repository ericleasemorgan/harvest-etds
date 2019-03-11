#!/usr/bin/env perl

# etd2generic.pl - given a ETD id, output a URL where it can be downloaded

# Eric Lease Morgan <emorgan@nd.edu>
# March 5, 2019 - first investigations


# configure
use constant SOLR  => 'https://solr41prod.library.nd.edu:8443/solr/curate';
use constant QUERY => 'is_part_of_ssim:info:fedora/';
use constant URL   => 'https://curate.nd.edu/downloads/';


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
	my $did = $doc->value_for( 'id' );
	$did =~ s/.*://g;
	warn "$did\n";
	my $url = URL . $did;
	warn "$url\n";
		
}

