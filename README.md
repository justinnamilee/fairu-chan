# fairu-chan
Cute script for sorting files, optionally can tell you about it, too.


---
# What it do, tho?
Scans one directory, uses mapping regex calls, applies some subroutines optionally, checks another directory, and makes sure they are "in sync".  It does this for a list of folders / regex maps provide in some file.

# Why, tho?
I use this on my Plex server setup to sort new files I dump to the ingest folder automatically based on the rules laid out in the YAML config file.

# How to do?
`$ perl fairu-chan your-config.yml run`

If you omit "run" it will just tell you what it _would_ do, but won't do it (useful).  You can also swap "run" for "daemon" and it'll check this stuff every so often automatically.

When you build the config file, if you want to make use of capture groups for the output you *NEED* to use _named_ captured groups like `(?<a_something>\d\d)` or `(?<b_thing> - \S+)`.  These get [lexically sorted](https://perldoc.perl.org/functions/sort) and put into `sprintf()` for ease of use.

If you want Discord support include the "discord" section as shown in the example, otherwise don't include it in the config at all.  You'll need to install the [WebService::Discord::Webhook](https://metacpan.org/pod/WebService::Discord::Webhook), [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL), and [Data::Validate::URI](https://metacpan.org/pod/Data::Validate::URI) Perl modules to use it.  I will likely add other notification types if I desire them...

# Signals when daemonized?
- `SIGTERM` will gracefully exit after current sleep or operation finishes.
- `SIGUSR1` run a check as soon as the next sleep is finished instead of waiting for the full idle timeout.
- `SIGUSR2` try to parse the config again, if it fails keep the current, otherwise update to the new one.
- `SIGINT` will just kill it where ever it is, no grace.

---

# Tech
Perl, duh!  I live like it's 1993.
