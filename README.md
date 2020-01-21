# Harvest ETDs

This suite of software -- Harvest ETDS -- is used to query the University of Notre Dame's institutional repository for electronic theses &amp; dissertations, cache the PDF files, and convert them into plain text for analysis. In a nutshell, this is how it works:

   * `./bin/db-create.sh` - create a rudimentary database (`./etc/curate-nd.db`) using `./etc/curate-nd.sql` as the schema
   * `./bin/etd-harvest.pl > ./caches/tsv/etd-harvest.tsv` - query the repository's Solr instance for ETDs, and cache the bibliographics to a TSV file
   * `./bin/db-initialize.sh` - loop through the TSV file and fill up the database
   
   * optionally and manually, use OpenRefine to normalize the contributors' and subjects' tables
   
   * `./bin/etd-iid2gid.sh` - given an item identifier, query the Solr instance and save the resulting generic item identifier to the database
   * `find pdf -name '*.pdf' | parallel ./bin/file2txt.sh {}` - convert the PDF files to plain text
   
There is one script to rule them all -- `./bin/etd-make.sh` -- but I'm sure your mileage will vary.

This has been "an adventure in Hydra", to say the least!!

---
Eric Lease Morgan &lt;emorgan@nd.edu&gt;   
January 20, 2020 - Martin Luther King Day
