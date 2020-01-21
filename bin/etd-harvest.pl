#!/usr/bin/env perl

# etd-harvest.pl - query CurateND's Solr instance and output a list of ETD metadata
# usage: ./bin/etd-harvest.pl > ./caches/tsv/etd-harvest.tsv


# Eric Lease Morgan <emorgan@nd.edu>
# March    5, 2019 - first investigations
# March   11, 2019 - made more specific to ETD
# January 20, 2020 - added abstract, contributors, and subject; Martin Luther King Day


# configure
use constant SOLR   => 'https://solr41prod.library.nd.edu:8443/solr/curate';
use constant QUERY  => '*:* AND active_fedora_model_ssi:Etd';
use constant ROWS   => 6000;
use constant HEADER => "iid\tmodel\tcreator\ttitle\tdate\tdepartment\tabstract\tcontributors\tsubjects\n";

# require
use strict;
use WebService::Solr;

# configure environment
binmode( STDOUT, ":utf8" );
binmode( STDERR, ":utf8" );
$| = 1;

# initialize
my $solr  = WebService::Solr->new( SOLR );
print HEADER;

# build a query and do the search
my $query                 = QUERY;
my %search_options        = ();
$search_options{ 'rows' } = ROWS;
my $response = $solr->search( $query, \%search_options );

# initialize results and loop through each document
for my $doc ( $response->docs ) {
	
	# parse
	my @creators     = $doc->values_for( 'desc_metadata__creator_tesim' );
	my $iid          = $doc->value_for ( 'id' );
	my $date         = $doc->value_for ( 'desc_metadata__date_approved_ssi' );
	my $department   = $doc->value_for ( 'desc_metadata__administrative_unit_tesim' );
	my $model        = $doc->value_for ( 'active_fedora_model_ssi' );
	my $title        = $doc->value_for ( 'desc_metadata__title_tesim' );
	my $abstract     = $doc->value_for ( 'desc_metadata__abstract_tesim' );
	my @contributors = $doc->values_for ( 'contributors_tesim' );
	my @subjects     = $doc->values_for ( 'desc_metadata__subject_tesim' );
	
	# add default date and department; duh!!!
	if ( $date eq '' )       { $date = '1904-01-01' }	
	if ( $department eq '' ) { $department = 'University of Notre Dame' }	

	# normalize
	$abstract =~ s/\n/ /g;
	$abstract =~ s/\t/ /g;
	$abstract =~ s/ +/ /g;
	
	my $contributors = join( "|", @contributors );
	my $subjects     = join( "|", @subjects );
	
	# debug
	warn "       item id: $iid\n";
	warn "         model: $model\n";
	warn "       creator: $creators[ 0 ]\n";
	warn "         title: $title\n";
	warn "          date: $date\n";
	warn "    department: $department\n";
	warn "  contributors: $contributors\n";
	warn "      subjects: $subjects\n";
	warn "      abstract: $abstract\n";
	warn "\n";	
			
	# update results
	print join( "\t", ( $iid, $model, $creators[ 0 ], $title, $date, $department, $abstract, $contributors, $subjects ) ), "\n";
	
}

# done
exit;
