#!/usr/bin/env python

# file2txt.py - given a non-plain text file, output a plain text file; a front-end to tika.jar

# Eric Lease Morgan <emorgan@nd.edu>
# January 8, 2019 - first cut, more or less


# require
from tika import parser
import sys
import tika

# sanity check
if len( sys.argv ) != 2 :
	sys.stderr.write( 'Usage: ' + sys.argv[ 0 ] + " <file>\n" )
	quit()

# initialize
tika.initVM()
file = sys.argv[ 1 ]

# do the work, output, and done
parsed = parser.from_file( file )
print( parsed[ "content" ] )
exit()
