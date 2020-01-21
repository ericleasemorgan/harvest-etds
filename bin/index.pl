#!/usr/bin/env perl

# index.pl - make the corpus searchable

# Eric Lease Morgan <emorgan@nd.edu>
# January 21, 2020 - first cut, but based on many other similar scripts

# configure
use constant DATABASE     => './etc/curate-nd.db';
use constant DRIVER       => 'SQLite';
use constant SOLR         => 'http://localhost:8983/solr/etds';
use constant QUERY        => 'SELECT * FROM etds ORDER BY iid;';
use constant SUBJECTS     => 'SELECT subject FROM subjects WHERE iid IS "##IID##" ORDER BY subject';
use constant CONTRIBUTORS => 'SELECT contributor FROM contributors WHERE iid IS "##IID##" ORDER BY contributor';
use constant TXT          => './txt';
use constant PREFIX       => 'und:';

use constant MAX      => 100;

# require
use DBI;
use strict;
use WebService::Solr;

# initialize
my $solr     = WebService::Solr->new( SOLR );
my $driver   = DRIVER; 
my $database = DATABASE;
my $txt      = TXT;
my $prefix   = PREFIX;
my $dbh      = DBI->connect( "DBI:$driver:dbname=$database", '', '', { RaiseError => 1 } ) or die $DBI::errstr;
binmode( STDOUT, ':utf8' );

# find all documents
my $handle = $dbh->prepare( QUERY );
$handle->execute() or die $DBI::errstr;

# process each document
my $i = 0;
while( my $document = $handle->fetchrow_hashref ) {
			
	# parse
	my $iid        = $$document{ 'iid' };
	my $gid        = $$document{ 'gid' };
	my $creator    = $$document{ 'creator' };
	my $title      = $$document{ 'title' };
	my $date       = $$document{ 'date' };
	my $abstract   = $$document{ 'abstract' };
	my $department = $$document{ 'department' };
	
	# remove bogus records; bogus in and of itself
	next if ( $iid eq 'iid' );
	next if ( ! $gid );
	
	# normalize abstract
	$abstract =~ s/\r/ /g;
	$abstract =~ s/\n/ /g;
	$abstract =~ s/ +/ /g;
	
	# get and normalize the full text
	my $fulltext = '';
	my $file     = "$txt/$gid.txt";
	$file        =~ s/$prefix//e;
	if ( -e $file ) {
	
		$fulltext = &slurp( $file );
		$fulltext    =~ s/\r//g;
		$fulltext    =~ s/\n/ /g;
		$fulltext    =~ s/ +/ /g;
		$fulltext    =~ s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//go;
	}
	
	# find all subjects
	my @subjects = ();
	my $query = SUBJECTS;
	$query =~ s/##IID##/$iid/;
	my $subhandle = $dbh->prepare( $query );
	$subhandle->execute() or die $DBI::errstr;
	while( my $document = $subhandle->fetchrow_hashref ) { push @subjects, $$document{ 'subject' } }

	# find all contributors
	my @contributors = ();
	my $query = CONTRIBUTORS;
	$query =~ s/##IID##/$iid/;
	my $subhandle = $dbh->prepare( $query );
	$subhandle->execute() or die $DBI::errstr;
	while( my $document = $subhandle->fetchrow_hashref ) { push @contributors, $$document{ 'contributor' } }

	# debug; dump
	warn "             iid: $iid\n";
	warn "             gid: $gid\n";
	warn "         creator: $creator\n";
	warn "           title: $title\n";
	warn "            date: $date\n";
	warn "      subject(s): " . join( '; ', @subjects ) . "\n";
	warn "  contributor(s): " . join( '; ', @contributors ) . "\n";
	warn "      department: $department\n";
	warn "        abstract: $abstract\n";
	warn "       full text: " . length( $fulltext ) . "\n";
	warn "\n";
		
	# initialize Solr data
	my $solr_iid        = WebService::Solr::Field->new( 'iid'        => $iid );
	my $solr_gid        = WebService::Solr::Field->new( 'gid'        => $gid );
	my $solr_creator    = WebService::Solr::Field->new( 'creator'    => $creator );
	my $solr_title      = WebService::Solr::Field->new( 'title'      => $title );
	my $solr_date       = WebService::Solr::Field->new( 'date'       => $date );
	my $solr_abstract   = WebService::Solr::Field->new( 'abstract'   => $abstract );
	my $solr_fulltext   = WebService::Solr::Field->new( 'fulltext'   => $fulltext );
	my $solr_department = WebService::Solr::Field->new( 'department' => $department );

	# add simple fields
	my $doc = WebService::Solr::Document->new;
	$doc->add_fields( $solr_iid,  $solr_gid, $solr_creator, $solr_title, $solr_date, $solr_abstract, $solr_fulltext, $solr_department );

	# add complex fields
	foreach ( @subjects )     { $doc->add_fields(( WebService::Solr::Field->new( 'subject'           => $_ ))) }
	foreach ( @subjects )     { $doc->add_fields(( WebService::Solr::Field->new( 'facet_subject'     => $_ ))) }
	foreach ( @contributors ) { $doc->add_fields(( WebService::Solr::Field->new( 'contributor'       => $_ ))) }
	foreach ( @contributors ) { $doc->add_fields(( WebService::Solr::Field->new( 'facet_contributor' => $_ ))) }

	# save/index
	$solr->add( $doc );

	$i++;
	#last if ( $i > MAX );
	
}

# done
exit;


sub slurp {

	my $f = shift;
	open ( F, $f ) or die "Can't open $f: $!\n";
	my $r = do { local $/; <F> };
	close F;
	return $r;

}