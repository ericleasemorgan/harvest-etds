#!/usr/bin/perl

# search.cgi - CGI interface to search a solr instance

# Eric Lease Morgan <emorgan@nd.edu>
# April 30, 2019 - first cut; based on Project English
# May    2, 2019 - added classification and files (urls)


# configure
use constant FACETFIELD => ( 'facet_subject', 'facet_author', 'facet_classification' );
use constant SOLR       => 'http://localhost:8983/solr/gutenberg';
use constant ROWS       => 199;
use constant NUMERALS   => ( '1'=>'I','2'=>'II','3'=>'III','4'=>'IV', '5'=>'V', '6'=>'VI', '7'=>'VII', '8'=>'VIII', '9'=>'IX', '10'=>'X' );

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
my %numerals = NUMERALS;

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
	my $items = '';
	my @gids  = ();
	
	# build the search options
	my %search_options                   = ();
	$search_options{ 'facet.field' }     = [ FACETFIELD ];
	$search_options{ 'facet' }           = 'true';
	$search_options{ 'rows' }            = ROWS;

	# search
	my $response = $solr->search( $query, \%search_options );

	# build a list of classification facets
	my @facet_classification = ();
	my $classification_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_classification } );
	foreach my $facet ( sort { $$classification_facets{ $b } <=> $$classification_facets{ $a } } keys %$classification_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/sandbox/gutenberg/cgi-bin/search.cgi?query=$sanitized AND classification:"$encoded"'>$facet</a>);
		push @facet_classification, $link . ' (' . $$classification_facets{ $facet } . ')';
		
	}

	# build a list of author facets
	my @facet_author = ();
	my $author_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_author } );
	foreach my $facet ( sort { $$author_facets{ $b } <=> $$author_facets{ $a } } keys %$author_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/sandbox/gutenberg/cgi-bin/search.cgi?query=$sanitized AND author:"$encoded"'>$facet</a>);
		push @facet_author, $link . ' (' . $$author_facets{ $facet } . ')';
		
	}

	# build a list of author facets
	my @facet_subject = ();
	my $subject_facets = &get_facets( $response->facet_counts->{ facet_fields }->{ facet_subject } );
	foreach my $facet ( sort { $$subject_facets{ $b } <=> $$subject_facets{ $a } } keys %$subject_facets ) {
	
		my $encoded = uri_encode( $facet );
		my $link = qq(<a href='/sandbox/gutenberg/cgi-bin/search.cgi?query=$sanitized AND subject:"$encoded"'>$facet</a>);
		push @facet_subject, $link . ' (' . $$subject_facets{ $facet } . ')';
		
	}

	# get the total number of hits
	my $total = $response->content->{ 'response' }->{ 'numFound' };

	# get number of hits
	my @hits = $response->docs;

	# loop through each document
	for my $doc ( $response->docs ) {
	
		# parse
		my $author = $doc->value_for( 'author' );
		my $title  = $doc->value_for( 'title' );
		my $gid    = $doc->value_for( 'gid' );
		my $file   = $doc->value_for( 'file' );
		
		# update the list of dids
		push(@gids, $gid );

		my @classifications = ();
		foreach my $classification ( $doc->values_for( 'classification' ) ) {
		
			my $classification = qq(<a href='/sandbox/gutenberg/cgi-bin/search.cgi?query=classification:"$classification"'>$classification</a>);
			push( @classifications, $classification );

		}
		@classifications = sort( @classifications );
		
		my @subjects = ();
		foreach my $subject ( $doc->values_for( 'subject' ) ) {
		
			my $subject = qq(<a href='/sandbox/gutenberg/cgi-bin/search.cgi?query=subject:"$subject"'>$subject</a>);
			push( @subjects, $subject );

		}
		@subjects = sort( @subjects );
		
		# create a cool list of subjects, a la catalog cards
		my $subjects = '';
		for ( my $i = 0; $i < scalar( @subjects ); $i++ ) {
		
			my $numeral = $numerals{ $i + 1 };
			$subjects .= $numeral . '. ' . @subjects[ $i ] . ' ';
			
		}

		# create a item
		my $item = &item( $title, $author, scalar( @subjects ), scalar( @classifications ), $gid );
		$item =~ s/##TITLE##/$title/g;
		$item =~ s/##AUTHOR##/$author/eg;
		$item =~ s/##FILE##/$file/eg;
		$item =~ s/##SUBJECTS##/$subjects/eg;
		$item =~ s/##CLASSIFICATIONS##/join( '; ', @classifications )/eg;
		$item =~ s/##GID##/$gid/ge;

		# update the list of items
		$items .= $item;
					
	}	

	my $gid2urls = &ids2urls;
	$gid2urls    =~ s/##IDS##/join( ' ', @gids )/e;

	# build the html
	$html =  &results_template;
	$html =~ s/##RESULTS##/&results/e;
	$html =~ s/##ID2URLS##/$gid2urls/ge;
	$html =~ s/##QUERY##/$sanitized/e;
	$html =~ s/##TOTAL##/$total/e;
	$html =~ s/##HITS##/scalar( @hits )/e;
	$html =~ s/##FACETSAUTHOR##/join( '; ', @facet_author )/e;
	$html =~ s/##FACETSSUBJECT##/join( '; ', @facet_subject )/e;
	$html =~ s/##FACETSCLASSIFICATION##/join( '; ', @facet_classification )/e;
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
	<p>Your search found ##TOTAL## item(s) and ##HITS## item(s) are displayed. ##ID2URLS##</p>
		
	<h3>Items</h3><ol>##ITEMS##</ol>
EOF

}


# specific item template
sub item {

	my $title           = shift;
	my $author          = shift;
	my $subjects        = shift;
	my $classifications = shift;
	my $item      = "<li class='item'><a href='##FILE##'>##TITLE##</a><ul>";
	if ( $author )          { $item .= "<li style='list-style-type:circle'>##AUTHOR##</li>" }
	if ( $subjects )        { $item .= "<li style='list-style-type:circle'>##SUBJECTS##</li>" }
	if ( $classifications ) { $item .= "<li style='list-style-type:circle'>##CLASSIFICATIONS##</li>" }
	$item .= "<li style='list-style-type:circle'>##GID##</li>";
	$item .= "</ul></li>";
	
	return $item;

}


# root template
sub template {

	return <<EOF
<html>
<head>
	<title>Project Gutenberg - Home</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="/sandbox/gutenberg/etc/style.css">
	<style>
		.item { margin-bottom: 1em }
	</style>
</head>
<body>
<div class="header">
	<h1>Project Gutenberg</h1>
</div>

<div class="col-3 col-m-3 menu">
  <ul>
		<li><a href="/sandbox/gutenberg/cgi-bin/search.cgi">Home</a></li>
		<li><a href="/sandbox/gutenberg/cgi-bin/gids2urls.cgi">Get URLs</a></li>
 </ul>
</div>

<div class="col-9 col-m-9">

	<p>This is selected fulltext index to the content of Project Gutenberg. Enter a query.</p>
	<p>
	<form method='GET' action='/sandbox/gutenberg/cgi-bin/search.cgi'>
	Query: <input type='text' name='query' value='##QUERY##' size='50' autofocus="autofocus"/>
	<input type='submit' value='Search' />
	</form>

	##RESULTS##

	<div class="footer">
		<p style='text-align: right'>
		Eric Lease Morgan<br />
		April 30, 2019
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
	<title>Project Gutenberg - Search results</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="/sandbox/gutenberg/etc/style.css">
	<style>
		.item { margin-bottom: 1em }
	</style>
</head>
<body>
<div class="header">
	<h1>Project Gutenberg - Search results</h1>
</div>

<div class="col-3 col-m-3 menu">
  <ul>
		<li><a href="/sandbox/gutenberg/cgi-bin/search.cgi">Home</a></li>
		<li><a href="/sandbox/gutenberg/cgi-bin/gids2urls.cgi">Get URLs</a></li>
 </ul>
</div>

	<div class="col-6 col-m-6">
		<p>
		<form method='GET' action='/sandbox/gutenberg/cgi-bin/search.cgi'>
		Query: <input type='text' name='query' value='##QUERY##' size='50' autofocus="autofocus"/>
		<input type='submit' value='Search' />
		</form>

		##RESULTS##
		
	</div>
	
	<div class="col-3 col-m-3">
	<h3>Author facets</h3><p>##FACETSAUTHOR##</p>
	<h3>Subject facets</h3><p>##FACETSSUBJECT##</p>
	<h3>Classification facets</h3><p>##FACETSCLASSIFICATION##</p>
	</div>

</body>
</html>
EOF

}

sub ids2urls {

	return <<EOF
(<a href="/sandbox/gutenberg/cgi-bin/gids2urls.cgi?gids=##IDS##">List URLs</a>)
EOF

}



