#!/usr/bin/perl
# Copyright 2020 Nathan Dorfman <ndorf@rtfm.net>
#
# Decorates /proc/net/arp entries with DNS names.
#
# Usage: harp.pl [filename...]
#
# Optionally specify one or more files to read from instead of /proc/net/arp.
# To read from stdin, specify '-'.
#

use strict;
use warnings;

use Socket;

if (!@ARGV) {
    use constant DEFAULT_FILE => '/proc/net/arp';
    open STDIN, DEFAULT_FILE || die DEFAULT_FILE . ": $!\n";
}

while (<>) {
    chomp;
    next if $_ eq 'IP address       HW type     Flags       HW address            Mask     Device';

    my ($ip, undef, undef, $eth, undef) = split;
    my $res = gethostbyaddr(inet_aton($ip), AF_INET);
    $res = '-' unless defined $res;

    printf "%-15s [%s] %s\n", $ip, $eth, $res;
}
