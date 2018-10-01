#!/usr/bin/perl
# Copyright 2018 Nathan Dorfman <ndorf@rtfm.net>
#
# Sorts filenames by mtime, for when you have too many for `xargs | ls -rt.'
#
# Usage: lart.pl [ --null | -0 ] [ --long | -l ] [ <files...> ]
# Options:
#   -0, --null      Delimiter is '\0' instead of '\n'
#   -l, --long      Print timestamps along with filenames
#
# If any <files...> are specified, the list of filenames to sort is read from
# therein; otherwise stdin.
#
# Example: find / -type f | lart.pl
#

use strict;
use warnings;

use File::stat;
use Getopt::Long;

my @files;

# Inserts into @files in sorted order:
sub process_filename {
    my ($name, $stat) = @_;
    my $file = [ $name, $stat ];

    if (!@files || $stat->mtime >= $files[$#files]->[1]->mtime) {
        push @files, $file;
        return;
    }

    my ($begin, $end) = (0, $#files);
    my $idx = 0;

    {
        do {
            if ($stat->mtime < $files[$idx]->[1]->mtime) {
                last if $stat->mtime >= $files[$idx - 1]->[1]->mtime;
                $end = $idx;
            }
            else {
                ++$idx;
                last if $begin == $end;
                $begin = $idx;
            }
            $idx = int(($begin + $end) / 2)
        } while ($idx);
    }

    splice(@files, $idx, 0, $file);
}

my $long_output;
GetOptions('0|null' => sub { $/ = "\0" },
           'l|long' => \$long_output);

while(<>) {
    chomp;
    my $stat = stat $_;
    $stat ? process_filename($_, $stat)
        : warn "$_: $!\n";
}

for (@files) {
    print scalar localtime $_->[1]->mtime, ': ' if $long_output;
    print $_->[0], $/;
}
