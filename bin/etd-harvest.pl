#!/usr/bin/env perl

# etd-harvest.pl - query CurateND's Solr instance and output a list of ETD metadata
# usage: ./bin/etd-harvest.pl > ./caches/tsv/etd-harvest.tsv

# consider the following QUERY for harvesting the Notre Dame graduation programs -- library_collections_tesim:"und:zp38w953h0s"


# Eric Lease Morgan <emorgan@nd.edu>
# March    5, 2019 - first investigations
# March   11, 2019 - made more specific to ETD
# January 20, 2020 - added abstract, contributors, and subject; Martin Luther King Day
# January 22, 2020 - parsed out college; added degree and discipline


# configure
use constant SOLR   => 'https://solr41prod.library.nd.edu:8443/solr/curate';
use constant QUERY  => '*:* AND active_fedora_model_ssi:Etd';
use constant ROWS   => 6000;
use constant HEADER => "iid\tmodel\tcreator\ttitle\tdate\tcollege\tabstract\tcontributors\tsubjects\tdegree\tdiscipline";

# require
use strict;
use WebService::Solr;

# configure environment
binmode( STDOUT, ":utf8" );
binmode( STDERR, ":utf8" );
$| = 1;

# initialize
my $solr  = WebService::Solr->new( SOLR );
print HEADER, "\n";

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
	my $degree       = $doc->value_for ( 'degree_name_tesim' );
	my $discipline   = $doc->value_for ( 'degree_disciplines_tesim' );
	my @contributors = $doc->values_for ( 'contributors_tesim' );
	my @subjects     = $doc->values_for ( 'desc_metadata__subject_tesim' );
	
	# add default date and department; duh!!!
	if ( $date eq '' )       { $date = '1904-01-01' }	
	if ( $department eq '' ) { $department = 'University of Notre Dame::unknown::unknown' }	
	
	my @parts = split( "::", $department );
	my $college = $parts[ 1 ];

	# normalize
	$abstract =~ s/\r/ /g;
	$abstract =~ s/\n/ /g;
	$abstract =~ s/\t/ /g;
	$abstract =~ s/ +/ /g;
	
	$title =~ s/\r/ /g;
	$title =~ s/\n/ /g;
	$title =~ s/\t/ /g;
	$title =~ s/ +/ /g;
	
	my $contributors = join( "|", @contributors );
	if ( ! $contributors ) { $contributors = 'none' }
	my $subjects     = join( "|", @subjects );
	if ( ! $subjects ) { $subjects = 'none' }
	
	# debug
	warn "       item id: $iid\n";
	warn "         model: $model\n";
	warn "       creator: $creators[ 0 ]\n";
	warn "         title: $title\n";
	warn "          date: $date\n";
	warn "       college: $college\n";
	warn "  contributors: $contributors\n";
	warn "      subjects: $subjects\n";
	warn "      abstract: $abstract\n";
	warn "        degree: $degree\n";
	warn "    discipline: $discipline\n";
	warn "\n";	
			
	# update results
	print join( "\t", ( $iid, $model, $creators[ 0 ], $title, $date, $college, $abstract, $contributors, $subjects, $degree, $discipline ) ), "\n";
	
}

# done
exit;
