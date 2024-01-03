# fairu-chan
File manager for automatic RSS stuff? Or something...


---
# What it do, tho?
Scans one directory, uses mapping regex calls, scans another directory, and makes sure they are "in sync".  It does this for a list of folders / regex maps provide in some file.

# Why, tho?
I use this on my Plex server setup to sort new files I dump to the ingest folder automatically based on the rules laid out in the YAML config file.

# How to do?
`$ perl run fairu-chan your-config.yml`

If you swap "run" for "validate" it will just tell you what it would do, but won't do it.

When you build the config file, if you want to be able to use capture groups for the sprintf you *NEED* to use named captured groups like `(?<a_something>\d\d)` or `(?<b_somethingelse> - \S+)`.  These get sorted and put into the sprintf in order for ease of use, which is why I tend to prefix them with a single letter then an underscore with some further description.

If you want Discord support include the "discord" section, otherwise omit it from the config.  You'll need to install the `WebService::Discord::Webhook`, `IO::Socket::SSL`, and `Data::Validate::URI` Perl modules to use it.


---

# Tech
Perl, duh!  I live like it's 1993.
