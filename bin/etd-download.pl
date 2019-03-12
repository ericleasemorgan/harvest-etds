#!/usr/bin/env perl

# etd-download.sh - given a URL and an output file, cache an ETD

# Eric Lease Morgan <emorgan@nd.edu>
# (c) University of Notre Dame; distributed under a GNU Public License

# March 12, 2019 - first cut


# configure
use constant TYPE => 'application/pdf';

# require
use strict;
use LWP::UserAgent;

# get input; sanity check
my $url  = $ARGV[ 0 ];
my $file = $ARGV[ 1 ];
if ( ! $url or ! $file ) { die "Usage: $0 <url> <file>\n" }

# initialize, configure some more, and do the work
my $useragent = LWP::UserAgent->new;
my $request   = HTTP::Request->new( GET => $url );
$request->content_type( TYPE );
my $response  = $useragent->request( $request );

# output, conditionally
if ( $response->is_success ) {

	# open the output, save, and clean up
    open FILE, " > $file" or die "Can't open $file ($!)\n";
    print FILE $response->content;
	close FILE;
	
}

# error
else { warn $response->status_line, "\n" }

# done
exit;
