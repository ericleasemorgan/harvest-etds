#!/usr/bin/env perl

# search.pl - command-line interface to search a solr instance

# Eric Lease Morgan <emorgan@nd.edu>
# January 21, 2020 - first cut against thus particular index


# configure
use constant FACETFIELD => ( 'facet_type' );
use constant SOLR       => 'http://localhost:8983/solr/etds';
use constant TXT        => './txt';
use constant PDF        => './pdf';
use constant PREFIX     => 'und:';
use constant ROWS       => 499;

# require
use strict;
use WebService::Solr;

# get input; sanity check
my $query  = $ARGV[ 0 ];
if ( ! $query ) { die "Usage: $0 <query>\n" }

# initialize
my $solr   = WebService::Solr->new( SOLR );
my $txt    = TXT;
my $pdf    = PDF;
my $prefix = PREFIX;

# build the search options
my %search_options = ();
#$search_options{ 'facet.field' } = [ FACETFIELD ];
#$search_options{ 'facet' }       = 'true';
$search_options{ 'rows' }        = ROWS;

# search
my $response = $solr->search( "$query", \%search_options );

# get the total number of hits
my $total = $response->content->{ 'response' }->{ 'numFound' };

# get number of hits returned
my @hits = $response->docs;

# start the (human-readable) output
print "Your search found $total item(s) and " . scalar( @hits ) . " item(s) are displayed.\n\n";

# loop through each document
for my $doc ( $response->docs ) {

	# parse
	my $iid      = $doc->value_for( 'iid' );
	my $gid      = $doc->value_for( 'gid' );
	my $creator  = $doc->value_for( 'creator' );
	my $title    = $doc->value_for( 'title' );
	my $date     = $doc->value_for( 'date' );
	my $abstract = $doc->value_for( 'abstract' );
	
	# create (and hack) cached file names
	my $plaintext   =  "$txt/$gid.txt";
	$plaintext      =~ s/$prefix//e;
	my $pdfdocument =  "$pdf/$gid.pdf";
	$pdfdocument    =~ s/$prefix//e;
	
	# output
	print "     creator: $creator\n";
	print "       title: $title\n";
	print "        date: $date\n";
	print "    abstract: $abstract\n";
	print "         iid: $iid\n";
	print "         gid: $gid\n";
	print "  plain text: $plaintext\n";
	print "         PDF: $pdfdocument\n";
	print "\n";
	
}

# done
exit;


# convert an array reference into a hash
sub get_facets {

	my $array_ref = shift;
	
	my %facets;
	my $i = 0;
	foreach ( @$array_ref ) {
	
		my $k = $array_ref->[ $i ]; $i++;
		my $v = $array_ref->[ $i ]; $i++;
		next if ( ! $v );
		$facets{ $k } = $v;
	 
	}
	
	return \%facets;
	
}

