# fairu-chan
File manager for automatic RSS stuff? Or something...


---
# What it do, tho?
Scans one directory, uses mapping regex calls, scans another directory, and makes sure they are "in sync".  It does this for a list of folders / regex maps provide in some file.

# Why, tho?
I use this on my Plex server setup to sort new files I dump to the ingest folder automatically based on the rules laid out in the YAML config file.

# How to do?
`perl fairu-chan your-config.yml run`

If you omit "run" it will just tell you what it would do, but won't do it.


---

# Tech
Perl, duh!  I live like it's 1993.
