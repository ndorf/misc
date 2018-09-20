#!/usr/bin/perl
# Copyright 2018 Nathan Dorfman <ndorf@rtfm.net>
#
# Checks whether specified files (or stdin by default) have holes in them.
# Unless the -q option is given, prints every hole found on stdout and every
# file without holes on stderr.
# Exit value is number of files in which holes were NOT found.

use strict;
use warnings;

# Check an open file handle for holes using SEEK_HOLE.
# In scalar context, returns a true value if at least one hole exists and a
# false one otherwise.
# In list context, returns a list containing of holes, each represented by a
# reference to a two-element array like [ OFFSET, LENGTH ].

sub check_handle_impl {
    my $fh = shift || die 'filehandle required';
    my $quick = !wantarray;

    use Fcntl qw(:seek);
    use constant SEEK_DATA => 3;
    use constant SEEK_HOLE => 4;

    seek($fh, 0, SEEK_END) || die "SEEK_END failed: $!";
    my $end = tell $fh;
    my $cur = 0;
    my $holes = $quick ? undef : [];
    while ($cur < $end) {
        seek($fh, $cur, SEEK_HOLE) || die "SEEK_HOLE failed: $!";
        my $hole = tell $fh;
        last if $hole == $end;
        return 1 if $quick;

        $cur = seek($fh, $hole, SEEK_DATA) ? tell $fh : $end;

        push @$holes, [ $hole, $cur - $hole ];
    }

    return $quick ? 0 : @$holes;
}

sub check_handle {
    my ($name, $handle, $quiet) = @_;
    return check_handle_impl($handle) if $quiet;

    my @holes = check_handle_impl($handle);
    if (@holes) {
        for (@holes) {
            printf "%s: %d-byte hole at offset %d\n", $name, $_->[1], $_->[0];
        }
        return scalar @holes;
    }

    print STDERR "$name doesn't have any holes.\n";
    return 0;
}

sub check_files {
    my $quiet = shift;
    my $count = 0;
    for (@_) {
        open(HANDLE, '<', $_) || die "$_: $!";
        eval { ++$count if !check_handle($_, *HANDLE, $quiet) };
        die "$_: $@" if $@;
        close HANDLE;
    }
    return $count;
}

use constant QUIET => (@ARGV && $ARGV[0] eq '-q') ? shift : 0;
exit(@ARGV ? check_files(QUIET, @ARGV) : !check_handle('<stdin>', *STDIN));
