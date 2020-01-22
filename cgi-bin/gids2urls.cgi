#!/usr/bin/perl

# gid2urls.cgi - given one more more identifiers, generate a list of urls pointing to plain text files

# Eric Lease Morgan <emorgan@nd.edu>
# (c) University of Notre Dame; distributed under a GNU Public License

# July 12, 2018 - first cut, but based on other work
# May   3, 2019 - migrating to Project Gutenberg


# configure
use constant HTTP       => 'http://cds.crc.nd.edu/etds';
use constant PREFIX     => 'und:';
use constant FILESYSTEM => '/afs/crc.nd.edu/user/e/emorgan/local/html/etds';

# require
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use strict;

# initialize
my $cgi        = CGI->new;
my $gids       = $cgi->param( 'gids' );
my $type       = $cgi->param( 'type' );
my $prefix     = PREFIX;
my $filesystem = FILESYSTEM;

# no input; display home page
if ( ! $gids || ! $type ) {

	print $cgi->header;
	print &form;
	
}

# process input
else {

	# get input and sanitize it
	my @gids =  ();
	$gids    =~ s/$prefix//g;
	$gids    =~ s/ +/ /g;
	@gids    =  split( ' ', $gids );

	# process each item in the found set
	my @urls = ();
	foreach my $gid ( @gids ) {
	
		# normalize and build; very fragile!
		$gid =~ s/$prefix//;
		if ( -e "$filesystem/$type/$gid.$type" ) {  push( @urls, HTTP . "/$type/$gid.$type" ) }
			
	}

	# dump the database and done
	print $cgi->header( -type => 'text/plain', -charset => 'utf-8');
	print join( "\n", @urls ), "\n";
	
}


# done
exit;


sub form {

	return <<EOF
<html>
<head>
	<title>Theses &amp; dissertations - Get URLs</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="/etds/etc/style.css">
	<style>
		.item { margin-bottom: 1em }
	</style>
</head>
<div class="header">
	<h1>Theses &amp; dissertations - Get URLs</h1>
</div>

	<div class="col-3 col-m-3 menu">
	  <ul>
		<li><a href="/etds/cgi-bin/search.cgi">Home</a></li>
		<li><a href="/etds/cgi-bin/gids2urls.cgi">Get URLs</a></li>
	 </ul>
	</div>

<div class="col-9 col-m-9">

	<p>Given a set of one or more identifiers, this program will return a list of URLs pointing to existing plain text versions or PDF versions of the items.</p>
	<form method='POST' action='/etds/cgi-bin/gids2urls.cgi'>
	Type: <input type="radio" name="type" value="txt" checked>Plain text</input>
	<input type="radio" name="type" value="pdf">PDF</input><br />
	
	Identifiers: <input type='text' name='gids' size='50' value='und:k930bv75m8t und:tq57np21k1j und:2227mp50n43 und:3x816m32x3c und:6t053f48091 und:70795714m4t und:5712m615j30 und:5712m615k6b und:br86b27960p und:wd375t38195 und:3b59183399t und:m900ns08f88 und:ng451g07r6m und:cz30pr78k45 und:tt44pk04v39 und:6q182j64q59 und:0r967367z7k und:bc386h4626z und:n870zp41782 und:m326m041v61 und:p8418k7418j und:4j03cz32k5m'/>
	<input type='submit' value='Get URLs' />
	</form>

	<div class="footer">
		<p style='text-align: right'>
		Eric Lease Morgan<br />
		January 22, 2020
		</p>
	</div>

</div>

</body>
</html>
EOF
	
}


