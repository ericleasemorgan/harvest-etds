#!/usr/bin/env perl

# search.pl - command-line interface to search a solr instance

# Eric Lease Morgan <emorgan@nd.edu>
# January 21, 2020 - first cut against thus particular index


# configure
use constant FACETFIELD => ( 'facet_subject', 'facet_contributor', 'facet_degree', 'facet_discipline', 'year', 'availability', 'facet_college' );
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
$search_options{ 'facet.field' } = [ FACETFIELD ];
$search_options{ 'facet' }       = 'true';
$search_options{ 'rows' }        = ROWS;

# search
my $response = $solr->search( "$query", \%search_options );

# build a list of subject facets
my @facet_subject = ();
my $subject_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_subject } );
foreach my $facet ( sort { $$subject_facets{ $b } <=> $$subject_facets{ $a } } keys %$subject_facets ) { push @facet_subject, $facet . ' (' . $$subject_facets{ $facet } . ')'; }

# build a list of contributor facets
my @facet_contributor = ();
my $contributor_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_contributor } );
foreach my $facet ( sort { $$contributor_facets{ $b } <=> $$contributor_facets{ $a } } keys %$contributor_facets ) { push @facet_contributor, $facet . ' (' . $$contributor_facets{ $facet } . ')'; }

# build a list of discipline facets
my @facet_discipline = ();
my $discipline_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_discipline } );
foreach my $facet ( sort { $$discipline_facets{ $b } <=> $$discipline_facets{ $a } } keys %$discipline_facets ) { push @facet_discipline, $facet . ' (' . $$discipline_facets{ $facet } . ')'; }

# build a list of degree facets
my @facet_degree = ();
my $degree_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_degree } );
foreach my $facet ( sort { $$degree_facets{ $b } <=> $$degree_facets{ $a } } keys %$degree_facets ) { push @facet_degree, $facet . ' (' . $$degree_facets{ $facet } . ')'; }

# build a list of degree facets
my @facet_year = ();
my $year_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ year } );
foreach my $facet ( sort { $$year_facets{ $b } <=> $$year_facets{ $a } } keys %$year_facets ) { push @facet_year, $facet . ' (' . $$year_facets{ $facet } . ')'; }

# build a list of availability facets
my @facet_availability = ();
my $availability_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ availability } );
foreach my $facet ( sort { $$availability_facets{ $b } <=> $$availability_facets{ $a } } keys %$availability_facets ) { push @facet_availability, $facet . ' (' . $$availability_facets{ $facet } . ')'; }

# build a list of colleges facets
my @facet_college = ();
my $college_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_college } );
foreach my $facet ( sort { $$college_facets{ $b } <=> $$college_facets{ $a } } keys %$college_facets ) { push @facet_college, $facet . ' (' . $$college_facets{ $facet } . ')'; }


# get the total number of hits
my $total = $response->content->{ 'response' }->{ 'numFound' };

# get number of hits returned
my @hits = $response->docs;

# start the (human-readable) output
print "Your search found $total item(s) and " . scalar( @hits ) . " item(s) are displayed.\n\n";
print '       subject facets: ', join( '; ', @facet_subject ), "\n\n";
print '   contributor facets: ', join( '; ', @facet_contributor ), "\n\n";
print '        degree facets: ', join( '; ', @facet_degree ), "\n\n";
print '    discipline facets: ', join( '; ', @facet_discipline ), "\n\n";
print '          year facets: ', join( '; ', @facet_year ), "\n\n";
print '  availability facets: ', join( '; ', @facet_availability ), "\n\n";
print '       college facets: ', join( '; ', @facet_college ), "\n\n";

# loop through each document
for my $doc ( $response->docs ) {

	# parse
	my $iid          = $doc->value_for(  'iid' );
	my $gid          = $doc->value_for(  'gid' );
	my $creator      = $doc->value_for(  'creator' );
	my $title        = $doc->value_for(  'title' );
	my $date         = $doc->value_for(  'date' );
	my $abstract     = $doc->value_for(  'abstract' );
	my $college      = $doc->value_for(  'college' );
	my $degree       = $doc->value_for(  'degree' );
	my $discipline   = $doc->value_for(  'discipline' );
	my @contributors = $doc->values_for( 'contributor' );
	my @subjects     = $doc->values_for( 'subject' );
	
	# create (and hack) cached file names
	my $plaintext   =  "$txt/$gid.txt";
	$plaintext      =~ s/$prefix//e;
	my $pdfdocument =  "$pdf/$gid.pdf";
	$pdfdocument    =~ s/$prefix//e;
	
	# output
	print "         creator: $creator\n";
	print "           title: $title\n";
	print "            date: $date\n";
	print "         college: $college\n";
	print "          degree: $degree\n";
	print "      discipline: $discipline\n";
	print "  contributor(s): " . join( '; ', @contributors ) . "\n";
	print "     subjects(s): " . join( '; ', @subjects ) . "\n";
	print "        abstract: $abstract\n";
	print "             iid: $iid\n";
	print "             gid: $gid\n";
	print "      plain text: $plaintext\n";
	print "             PDF: $pdfdocument\n";
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

