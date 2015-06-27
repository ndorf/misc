#!/usr/bin/perl -w
# Copyright 2015 Nathan Dorfman <ndorf@rtfm.net>
#
# Checks whether hosts are allowed by domains' SPF policies.
# Expected results go to STDOUT and others to STDERR for easy filtering.
# Specify hosts expected to pass with -h, or fail with -b.
# Use -b without host to check a default, illegal one.
# Use -p to read the relay host from a Postfix config file.
#
# Examples:
#   ./check_spf_rules.pl -b known.spammer.net my.domain my.domain2 ...
#       (check that spammer is blocked)
#   ./check_spf_rules.pl -b -h `hostname` my.domain my.domain2 ...
#       (check that we are allowed, and that default is blocked)
#   ./check_spf_rules.pl -p /etc/mail/postmail.cf my.domain my.domain2 ...
#       (check that postfix relayhost is allowed. instead of optional
#       filename, another option or -- may follow to use this default)
#   ./check_spf_rules.pl -p -h gmail.com my.domain my.domain2 ...
#       (check that postfix relayhost and favorite forwarder are allowed)
#
# Example crontab:
# mm hh dd * * check_spf_rules.pl -b -p -- $MY_DOMAINS > /dev/null

use Mail::SPF;
use Socket;
use Getopt::Long;
use strict;

{
    my (@good, @bad);

    GetOptions(
            "host=s"        => \@good,
            "badhost:s@"    => \@bad,
            "postfixcf:s"   => sub { push @good, get_postfix_relayhost($_[1]) }
            );

    die "Usage: $0 -p <postfixcf> | -h <host1> [-r <host2> ... ] domains...\n"
        unless @ARGV && (@good || @bad);

    my $spf = Mail::SPF::Server->new();

    for my $domain (@ARGV) {
        for my $host (@good) {
            check_host_domain($spf, $host, $domain, 'pass');
        }
        for my $host (@bad) {
            $host = '192.168.1.1' unless $host;
            check_host_domain($spf, $host, $domain, 'softfail', 'fail');
        }
    }
}

sub get_postfix_relayhost {
    my $file = ($_[0] || '/etc/postfix/main.cf');
    my $result;

    open(my $FH, $file) || die "failed to read postfix config file '$file'\n";
    while(<$FH>) {
        if (/^relayhost\s*=\s*(\[?)(.*)(?(1)\]|)\s*$/) {
            $result = (defined $result) ? undef : $2;
        }
    }
    close $FH;

    die "failed to read relayhost directive from postfix config file '$file'\n"
        unless defined $result;

    return $result;
}

sub check_host_domain {
    my ($spf, $host, $domain, @x) = @_;

    my $addr = gethostbyname $host;
    unless (defined $addr) {
        print STDERR "$host not found\n";
        return;
    }

    my $result = $spf->process(Mail::SPF::Request->new(
        scope       => 'mfrom',
        identity    => 'user@' . $domain,
        ip_address  => inet_ntoa($addr)
    ));

    my $o = grep($result->is_code($_), @x) ? *STDOUT : *STDERR;
    print $o "$domain from $host: $result\n";
}
