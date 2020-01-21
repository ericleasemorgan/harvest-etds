-- curate.sql - a database representing curateND

-- Eric Lease Morgan (emorgan@nd.edu)
-- (c) University of Notre Dame; distributed under a GNU Public License

-- March   11, 2019 - first cut
-- January 20, 2020 - added contributors and subjects; Martin Luther King Day


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


CREATE table contributors (
  iid          TEXT,
  contributor  TEXT
);


CREATE table subjects (
  iid      TEXT,
  subject  TEXT
);

