#!/usr/bin/perl

# search.cgi - CGI interface to search a solr instance

# Eric Lease Morgan <emorgan@nd.edu>
# January 21, 2020 - first cut for this instance
# January 22, 2020 - added many facets


# configure
use constant FACETFIELD => ( 'facet_subject', 'facet_contributor', 'facet_degree', 'facet_discipline', 'year', 'availability', 'facet_college' );
use constant SOLR       => 'http://localhost:8983/solr/etds';
use constant TXT        => 'txt';
use constant PDF        => 'pdf';
use constant PREFIX     => 'und:';
use constant FILESYSTEM => '/afs/crc.nd.edu/user/e/emorgan/local/html/etds';
use constant HTTP       => 'http://cds.crc.nd.edu/etds';
use constant ROWS       => 199;

# require
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Entities;
use strict;
use WebService::Solr;
use URI::Encode qw(uri_encode uri_decode);

# initialize
my $cgi      = CGI->new;
my $query    = $cgi->param( 'query' );
my $html     = &template;
my $solr     = WebService::Solr->new( SOLR );

# sanitize query
my $sanitized = HTML::Entities::encode( $query );

# display the home page
if ( ! $query ) {

	$html =~ s/##QUERY##//;
	$html =~ s/##RESULTS##//;

}

# search
else {

	# re-initialize
	my @gids       = ();
	my $filesystem = FILESYSTEM;
	my $http       = HTTP;
	my $items      = '';
	my $pdf        = PDF;
	my $prefix     = PREFIX;
	my $txt        = TXT;
	
	# build the search options
	my %search_options                   = ();
	$search_options{ 'facet.field' }     = [ FACETFIELD ];
	$search_options{ 'facet' }           = 'true';
	$search_options{ 'rows' }            = ROWS;

	# search
	my $response = $solr->search( $query, \%search_options );

	# build a list of subject facets
	my @facet_subject = ();
	my $subject_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_subject } );
	foreach my $facet ( sort { $$subject_facets{ $b } <=> $$subject_facets{ $a } } keys %$subject_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/etds/cgi-bin/search.cgi?query=$sanitized AND subject:"$encoded"'>$facet</a>);
		push @facet_subject, $link . ' (' . $$subject_facets{ $facet } . ')';
		
	}

	# build a list of contributor facets
	my @facet_contributor = ();
	my $contributor_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_contributor } );
	foreach my $facet ( sort { $$contributor_facets{ $b } <=> $$contributor_facets{ $a } } keys %$contributor_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/etds/cgi-bin/search.cgi?query=$sanitized AND contributor:"$encoded"'>$facet</a>);
		push @facet_contributor, $link . ' (' . $$contributor_facets{ $facet } . ')';
		
	}

	# build a list of degree facets
	my @facet_degree = ();
	my $degree_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_degree } );
	foreach my $facet ( sort { $$degree_facets{ $b } <=> $$degree_facets{ $a } } keys %$degree_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/etds/cgi-bin/search.cgi?query=$sanitized AND degree:"$encoded"'>$facet</a>);
		push @facet_degree, $link . ' (' . $$degree_facets{ $facet } . ')';
		
	}

	# build a list of discipline facets
	my @facet_discipline = ();
	my $discipline_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_discipline } );
	foreach my $facet ( sort { $$discipline_facets{ $b } <=> $$discipline_facets{ $a } } keys %$discipline_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/etds/cgi-bin/search.cgi?query=$sanitized AND discipline:"$encoded"'>$facet</a>);
		push @facet_discipline, $link . ' (' . $$discipline_facets{ $facet } . ')';
		
	}

	# build a list of year facets
	my @facet_year = ();
	my $year_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ year } );
	foreach my $facet ( sort { $$year_facets{ $b } <=> $$year_facets{ $a } } keys %$year_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/etds/cgi-bin/search.cgi?query=$sanitized AND year:"$encoded"'>$facet</a>);
		push @facet_year, $link . ' (' . $$year_facets{ $facet } . ')';
		
	}

	# build a list of availability facets
	my @facet_availability = ();
	my $availability_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ availability } );
	foreach my $facet ( sort { $$availability_facets{ $b } <=> $$availability_facets{ $a } } keys %$availability_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/etds/cgi-bin/search.cgi?query=$sanitized AND availability:"$encoded"'>$facet</a>);
		push @facet_availability, $link . ' (' . $$availability_facets{ $facet } . ')';
		
	}

	# build a list of colleges facets
	my @facet_college = ();
	my $college_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_college } );
	foreach my $facet ( sort { $$college_facets{ $b } <=> $$college_facets{ $a } } keys %$college_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/etds/cgi-bin/search.cgi?query=$sanitized AND college:"$encoded"'>$facet</a>);
		push @facet_college, $link . ' (' . $$college_facets{ $facet } . ')';
		
	}

	# get the total number of hits
	my $total = $response->content->{ 'response' }->{ 'numFound' };

	# get number of hits
	my @hits = $response->docs;

	# loop through each document
	for my $doc ( $response->docs ) {
	
		# parse
		my $iid          = $doc->value_for(  'iid' );
		my $gid          = $doc->value_for(  'gid' );
		my $creator      = $doc->value_for(  'creator' );
		my $title        = $doc->value_for(  'title' );
		my $date         = $doc->value_for(  'date' );
		my $abstract     = $doc->value_for(  'abstract' );
		my $degree       = $doc->value_for(  'degree' );
		my $discipline   = $doc->value_for(  'discipline' );
		my $college      = $doc->value_for(  'college' );
		
		# update the list of dids
		push( @gids, $gid );
		
		# create a list of subjects
		my @subjects = ();
		foreach my $subject ( $doc->values_for( 'subject' ) ) {
		
			my $subject = qq(<a href='/etds/cgi-bin/search.cgi?query=subject:"$subject"'>$subject</a>);
			push( @subjects, $subject );

		}
		@subjects    = sort( @subjects );
		my $subjects = join( '; ', @subjects );

		# create a list of contributors
		my @contributors = ();
		foreach my $contributor ( $doc->values_for( 'contributor' ) ) {
		
			my $contributor = qq(<a href='/etds/cgi-bin/search.cgi?query=contributor:"$contributor"'>$contributor</a>);
			push( @contributors, $contributor );

		}
		@contributors    = sort( @contributors );
		my $contributors = join( '; ', @contributors );

		# create links to plain text
		my $plaintext =  "$filesystem/$txt/$gid.txt";
		my $txturl    =  '';
		$plaintext    =~ s/$prefix//;
		if ( -e $plaintext ) { $txturl = "$http/$txt/$gid.txt" }
		$txturl    =~ s/$prefix//;
		
		# create links to pdf
		my $pdfdocument =  "$filesystem/$pdf/$gid.pdf";
		my $pdfurl      =  '';
		$pdfdocument    =~ s/$prefix//;
		if ( -e $pdfdocument ) { $pdfurl = "$http/$pdf/$gid.pdf" }
		$pdfurl    =~ s/$prefix//;
		
		# create a item
		my $item = &item( $title, $creator, $date, scalar( @subjects ), scalar( @contributors ), $txturl, $pdfurl, $degree, $discipline, $college );
		$item =~ s/##TITLE##/$title/g;
		$item =~ s/##CREATOR##/$creator/eg;
		$item =~ s/##DATE##/$date/eg;
		$item =~ s/##DISCIPLINE##/$discipline/eg;
		$item =~ s/##COLLEGE##/$college/eg;
		$item =~ s/##DEGREE##/$degree/eg;
		$item =~ s/##DATE##/$date/eg;
		$item =~ s/##SUBJECTS##/$subjects/eg;
		$item =~ s/##CONTRIBUTORS##/$contributors/eg;
		$item =~ s/##PLAINTEXT##/$txturl/eg;
		$item =~ s/##PDFDOCUMENT##/$pdfurl/eg;
		$item =~ s/##GID##/$gid/ge;

		# update the list of items
		$items .= $item;
					
	}	

	my $gid2urls = &ids2urls;
	$gid2urls    =~ s/##IDS##/join( ' ', @gids )/ge;

	# build the html
	$html =  &results_template;
	$html =~ s/##RESULTS##/&results/e;
	$html =~ s/##ID2URLS##/$gid2urls/ge;
	$html =~ s/##QUERY##/$sanitized/e;
	$html =~ s/##TOTAL##/$total/e;
	$html =~ s/##HITS##/scalar( @hits )/e;
	$html =~ s/##FACETSSUBJECT##/join( '; ', @facet_subject )/e;
	$html =~ s/##FACETSCONTRIBUTOR##/join( '; ', @facet_contributor )/e;
	$html =~ s/##FACETSDEGREE##/join( '; ', @facet_degree )/e;
	$html =~ s/##FACETSDISCIPLINE##/join( '; ', @facet_discipline )/e;
	$html =~ s/##FACETSYEAR##/join( '; ', @facet_year )/e;
	$html =~ s/##FACETSAVAILABILITY##/join( '; ', @facet_availability )/e;
	$html =~ s/##FACETSCOLLEGE##/join( '; ', @facet_college )/e;
	$html =~ s/##ITEMS##/$items/e;

}

# done
print $cgi->header( -type => 'text/html', -charset => 'utf-8');
print $html;
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


# search results template
sub results {

	return <<EOF
	<p>Your search found ##TOTAL## item(s) and ##HITS## item(s) are displayed.</p>
	</p>##ID2URLS##</p>
		
	<h3>Items</h3><ol>##ITEMS##</ol>
EOF

}


# specific item template
sub item {

	my $title           = shift;
	my $author          = shift;
	my $date            = shift;
	my $subjects        = shift;
	my $contributors    = shift;
	my $txturl          = shift;
	my $pdfurl          = shift;
	my $degree          = shift;
	my $discipline      = shift;
	my $college         = shift;
	my $item            = "<li class='item'><span class='title'>##TITLE##</span><ul>";
	if ( $author )       { $item .= "<li style='list-style-type:circle'><b>author:</b> ##CREATOR##</li>" }
	if ( $degree )       { $item .= "<li style='list-style-type:circle'><b>degree:</b> ##DEGREE##</li>" }
	if ( $college )      { $item .= "<li style='list-style-type:circle'><b>college:</b> ##COLLEGE##</li>" }
	if ( $discipline )   { $item .= "<li style='list-style-type:circle'><b>discipline:</b> ##DISCIPLINE##</li>" }
	if ( $date )         { $item .= "<li style='list-style-type:circle'><b>date:</b> ##DATE##</li>" }
	if ( $subjects )     { $item .= "<li style='list-style-type:circle'><b>subject(s):</b> ##SUBJECTS##</li>" }
	if ( $contributors ) { $item .= "<li style='list-style-type:circle'><b>contributor(s):</b> ##CONTRIBUTORS##</li>" }
	if ( $txturl )       { $item .= "<li style='list-style-type:circle'><b>plain text:</b> <a href='##PLAINTEXT##'>##PLAINTEXT##</a></li>" }
	if ( $pdfurl )       { $item .= "<li style='list-style-type:circle'><b>PDF:</b> <a href='##PDFDOCUMENT##'>##PDFDOCUMENT##</a></li>" }
	$item .= "<li style='list-style-type:circle'><b>identifier:</b> ##GID##</li>";
	$item .= "</ul></li>";
	
	return $item;

}


# root template
sub template {

	return <<EOF
<html>
<head>
	<title>Theses &amp; dissertations - Home</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="/etds/etc/style.css">
	<style>
		.item { margin-bottom: 1em }
	</style>
</head>
<body>
<div class="header">
	<h1>Theses &amp; dissertations</h1>
</div>

<div class="col-3 col-m-3 menu">
  <ul>
		<li><a href="/etds/cgi-bin/search.cgi">Home</a></li>
		<li><a href="/etds/cgi-bin/gids2urls.cgi">Get URLs</a></li>
 </ul>
</div>

<div class="col-9 col-m-9">

	<p>This is selected fulltext index (of many/most of the) theses &amp; dissertations from the University of Notre Dame. Enter a query.</p>
	<p>
	<form method='GET' action='/etds/cgi-bin/search.cgi'>
	Query: <input type='text' name='query' value='##QUERY##' size='50' autofocus="autofocus"/>
	<input type='submit' value='Search' />
	</form>

	##RESULTS##

	<div class="footer">
		<p style='text-align: right'>
		Eric Lease Morgan<br />
		January 21, 2020
		</p>
	</div>

</div>

</body>
</html>
EOF

}


# results template
sub results_template {

	return <<EOF
<html>
<head>
	<title>Theses &amp; dissertations - Search results</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="/etds/etc/style.css">
	<style>
		.item { margin-bottom: 1em }
		.title { font-size: large }
	</style>
</head>
<body>
<div class="header">
	<h1>Theses &amp; dissertations - Search results</h1>
</div>

<div class="col-3 col-m-3 menu">
  <ul>
		<li><a href="/etds/cgi-bin/search.cgi">Home</a></li>
		<li><a href="/etds/cgi-bin/gids2urls.cgi">Get URLs</a></li>
 </ul>
</div>

	<div class="col-6 col-m-6">
		<p>
		<form method='GET' action='/etds/cgi-bin/search.cgi'>
		Query: <input type='text' name='query' value='##QUERY##' size='50' autofocus="autofocus"/>
		<input type='submit' value='Search' />
		</form>

		##RESULTS##
		
	</div>
	
	<div class="col-3 col-m-3">
		<h3>College, school, & institute facets</h3><p>##FACETSCOLLEGE##</p>
		<h3>Discipline facets</h3><p>##FACETSDISCIPLINE##</p>
		<h3>Year facets</h3><p>##FACETSYEAR##</p>
		<h3>Degree facets</h3><p>##FACETSDEGREE##</p>
		<h3>Availability facets</h3><p>##FACETSAVAILABILITY##</p>
		<h3>Subject facets</h3><p>##FACETSSUBJECT##</p>
		<h3>Contributor facets</h3><p>##FACETSCONTRIBUTOR##</p>
	</div>

</body>
</html>
EOF

}

sub ids2urls {

	return <<EOF
<a href="/etds/cgi-bin/gids2urls.cgi?type=txt&gids=##IDS##">List URLs to available plain text versions of documents</a>, or <a href="/etds/cgi-bin/gids2urls.cgi?type=pdf&gids=##IDS##">list URLs to available PDF versions</a>.
EOF

}



