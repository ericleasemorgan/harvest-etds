-- curate.sql - a database representing curateND

-- Eric Lease Morgan (emorgan@nd.edu)
-- (c) University of Notre Dame; distributed under a GNU Public License

-- March 11, 2019 - first cut


CREATE table etds (
  eid        INTEGER PRIMARY KEY,
  iid        TEXT,
  model      TEXT,
  creator    TEXT,
  title      TEXT,
  date       TEXT,
  department TEXT,
  abstract   TEXT,
  gid        TEXT
);
