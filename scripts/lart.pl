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

package SortedList;

sub new {
    my $type = shift;
    my $cmp = (shift || sub { $_[0] cmp $_[1] });

    bless { cmp => $cmp, data => [] }, $type;
}

sub data { $_[0]->{data} }

sub insert {
    my $self = shift;
    my $new_data = shift;
    my $cmp = $self->{cmp};
    my $data = $self->{data};
    my $end = $#$data;

    if (!@$data || &$cmp($new_data, $$data[$end]) >= 0) {
        push @$data, $new_data;
        return;
    }

    my $idx = 0;
    my $begin = 0;

    for (;;) {
        if (&$cmp($new_data, $$data[$idx]) < 0) {
            last if $idx == $begin || &$cmp($new_data, $$data[$idx - 1]) >= 0;
            $end = $idx;
        }
        else {
            $begin = $idx + 1;
        }
        $idx = int(($begin + $end) / 2)
    }

    splice @$data, $idx, 0, $new_data;
}

package main;

my $long_output;
GetOptions('0|null' => sub { $/ = "\0" },
           'l|long' => \$long_output);

my $files = new SortedList(
    sub {
        $_[0]->[1]->mtime <=> $_[1]->[1]->mtime;
    }
);

while(<>) {
    chomp;
    my $stat = stat $_;
    $stat ? $files->insert([ $_, $stat ])
        : warn "$_: $!\n";
}

for (@{$files->data}) {
    print scalar localtime $_->[1]->mtime, ': ' if $long_output;
    print $_->[0], $/;
}
