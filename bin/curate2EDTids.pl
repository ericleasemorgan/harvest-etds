#!/usr/bin/env perl

# curate2EDTids.pl - query CurateND's Solr instance and output a list of ETD metadata

# Eric Lease Morgan <emorgan@nd.edu>
# March 5, 2019 - first investigations


# configure
use constant SOLR   => 'https://solr41prod.library.nd.edu:8443/solr/curate';
use constant QUERY  => '*:* AND active_fedora_model_ssi:Etd';
use constant ROWS   => 4000;
use constant HEADER => "id\tcreator\ttitle\tdate\tdepartment\tabstract\n";

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
	my @creators   =  $doc->values_for( 'desc_metadata__creator_tesim' );
	my $abstract   =  $doc->value_for ( 'desc_metadata__abstract_tesim' );
	   $abstract   =~ s/\s+/ /g;
	my $cid        =  $doc->value_for ( 'id' );
	my $date       =  $doc->value_for ( 'desc_metadata__date_approved_ssi' );
	my $department =  $doc->value_for ( 'desc_metadata__administrative_unit_tesim' );
	my $model      =  $doc->value_for ( 'active_fedora_model_ssi' );
	my $title      =  $doc->value_for ( 'desc_metadata__title_tesim' );
	
	# debug
	warn "   curate id: $cid\n";
	warn "     creator: $creators[ 0 ]\n";
	warn "       title: $title\n";
	warn "        date: $date\n";
	warn "  department: $department\n";
	warn "    abstract: $abstract\n";
	warn "       model: $model\n";
	warn "\n";	
	
	# update results
	push( @results, join( "\t", ( $cid, $creators[ 0 ], $title, $date, $department, $abstract ) ) );
	
}

# output and done
print HEADER;
for my $result ( @results ) { print "$result\n" }
exit;
