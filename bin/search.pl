#!/usr/bin/env perl

# search.pl - query CurateND's Solr instance and output a stream of TSV

# Eric Lease Morgan <emorgan@nd.edu>
# March 5, 2019 - first investigations


# configure
use constant SOLR   => 'https://solr41prod.library.nd.edu:8443/solr/curate';
use constant QUERY  => "*:*";
use constant ROWS   => 10000;
use constant HEADER => "id\tcreator\ttitle\tmodel\n";

# require
use strict;
use WebService::Solr;

# configure environment
binmode( STDOUT, ":utf8" );
binmode( STDERR, ":utf8" );
$| = 1;

# initialize
my $solr  = WebService::Solr->new( SOLR );

# build a query and do the search
my $query                 = QUERY;
my %search_options        = ();
$search_options{ 'rows' } = ROWS;
my $response = $solr->search( $query, \%search_options );

# initialize results and loop through each document
my @results = ();
for my $doc ( $response->docs ) {
	
	# parse
	my $cid      = $doc->value_for ( 'id' );
	my @creators = $doc->values_for( 'desc_metadata__creator_tesim' );
	my $title    = $doc->value_for ( 'desc_metadata__title_tesim' );
	my $model    = $doc->value_for ( 'active_fedora_model_ssi' );
	
	# debug
	warn "  curate id: $cid\n";
	warn "    creator: $creators[ 0 ]\n";
	warn "      title: $title\n";
	warn "      model: $model\n";
	warn "\n";	
	
	# update results
	push( @results, join( "\t", ( $cid, $creators[ 0 ], $title, $model ) ) );
	
}

# output and done
print HEADER;
for my $result ( @results ) { print "$result\n" }
exit;
