# NAME

RENAME.PL - Pretty under-engineered if you ask me.

# USAGE

RENAME.PL \[-hvcerwim -d &lt;path> -f &lt;filter> -s &lt;map>\] <1:regex> <2:format>

# DESCRIPTION

Rename files and stuff with the power of **REGEX** and **Perl**.  It uses named capture groups in **REGEX**, optionally passes them to a matching named subroutine, then it stuffs them into your provided format for `sprintf()`.

# THE EASY STUFF

- HELP **-h|--help**

    Duh.

- VERBOSE **-v|--verbose**

    Print's event information as it happens.  Add a second for **DEBUG** mode.

- COPY **-c|--copy**

    Do you want to copy the files instead of moving them (default)?

- DIRECTORY **-d|--directory path**

    Defaults to '.', make sure you have your filter set!

- RUN **-e|--execute**

    If this is not include the script does nothing to the actual files (default).

- RECURSIVE **-r|--recursive**

    Do I scan sub-directories as well?

- FILTERS **-f|--filter list**

    Only grab paths that match these pre-filters, compiled as `qr/@{[ q[\\.(?:] . join(q[|], @filter) . q[)$] ]}/i`.

    Input should be a string of extensions separated by FILT\_SEP (defaults to ','), like: 'mkv,mp4'.

- WAIT **-w|--wait**

    Do not exit the script until enter is pressed.

- INTERNAL **-i|--internal**

    Use internal `rename()` instead of `File::Copy::move()`.  This option is probably not what you want ever.

- MANUAL **-m|--manual**

    Disable automatic "path" and "extension" capture.  You will need to provide matches for your path that come first and extension that come last (or not, whatever).

# GORY DETAILS

## INPUT REGEX (**ARG1**)

Your **REGEX** will be passed the complete file name from the input path (**-d** or '.' by default).  It must return a successful match or the file in question will be skipped.

To get data to the output formatter capture groups are used.  The capture groups MUST be named and will be sorted by alphabetical order before being passed to the output formatter.

### Example (with **-m**):

    INPUT: '~/videos/bad_named_tv/your_show_310_h264_1080p.mkv'
    REGEX: qr/^(?<a_path>.+?)your_show(?<b_season>\d)(?<c_episode>\d+).+$/

### Results:

    {
      a_path    => '~/videos/bad_named_tv/',
      b_season  => 3,
      c_episode => 10
    }

## OUTPUT FORMAT (**ARG2**)

Once all named capture groups have been mapped (if applicable), they are sorted alphabetically and stuffed into `sprintf()`.

## MAPPING SUBROUTINES **-s|--subroutine hash**

After matching has been completed on an input path **rename.pl** will look for subroutines to be called on each named capture group's result.  Input to **-s** should be a string containing a list of key-value pairs, like:

    -s 'a_one => sub {uc(shift)}, b_two => sub {lc(shift)}'

### Example (with **-m**):

    INPUT: { a_path => '~/videos/bad_named_tv/' }
    MAP:   { a_path => sub { my (@path) = split('/',shift); pop(@path); push(@path, 'sorted_tv'); return join('/',@path) } }

### Results:

    {
      a_path    => '~/videos/sorted_tv',
      b_season  => 3,
      c_episode => 10
    }

### Example (with **-m**):

    INPUT:  { a_path => '~/videos/sorted_tv', b_season => 3, c_episode => 10 }
    FORMAT: '%s/Your Show S%02dE%02d.mkv'

### Results:

    '~/videos/sorted_tv/Your Show S03E10.mkv'

# EXAMPLES

    Convert TV named like "~/videos/bad_named_tv/SomeShow - 6.66.mp4" to "~/videos/bad_named_tv/SomeShow - S06E66.mp4"

      $ rename.pl -m -d ~/videos/bad_named_tv '^(?<a_path>.+?)s+-s+(?<b_sn>\d).(?<c_en>\d\d).(?<d_ext>.+)' '%s - S%02dE%02d.%s' -e

    Convert by copying a 6-disc album (20 tracks per disc) named like "~/music/bad_multi_cd/Artist [Album 6CD Set] Disk 3.16.mp3" to "~/music/bad_multi_cd/Artist (Album) 056.mp3"

      $ rename.pl -cd ~/music/bad_multi_cd '^(?<a_artist>.+?)\s+\[(?<b_album>.+?)\]\s+Disk\s+(?<c_num>\d\.\d+)' '%s (%s) %03d' -s 'c_num => sub { my ($d,$t) = split(q[.], shift); return (($d-1)*20 + $t) }' 

    Take files out of subfolders and put them into the main directory by converting 'Season 1/Johnny Bravo 1x03b Some title.avi' to 'Johnny Bravo S01E03 (Part 02) Some title.avi', etc.

      $ rename.pl '^.+? - (?<a_season>\d+)x(?<b_episode>\d+)(?<c_part>\w) - (?<d_extra>.+)' 'Johnny Bravo S%02dE%02d (Part %02d) %s' -s 'c_part => sub { return (defined($_[0]) ? (ord(shift) - 96) : 0) }' -rm

# AUTHOR

Justin Lee ["justin dot nami dot lee at gmail dot com"](#justin-dot-nami-dot-lee-at-gmail-dot-com)

# HOMEWORK

- [perlre](https://metacpan.org/pod/perlre): https://perldoc.perl.org/perlre.html
- [perlsub](https://metacpan.org/pod/perlsub): https://perldoc.perl.org/perlsub.html
