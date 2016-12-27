#!/usr/bin/env perl

use strict;
use warnings;
use Data::Printer;

my $bundle_f = $ARGV[0];

my %dict = ();

while (my $line = <STDIN>) {
    chomp $line;
    my ($id, @rest) = split /\t/, $line;
    $id =~ s/^.*\///;
    $id =~ s/txt/streex/;
    $dict{$id} = [ @rest ];
}

open my $fh, "<:utf8", $bundle_f or die $!;
while (my $line = <$fh>) {
    chomp $line;
    my $id = $line;
    $id =~ s/^.*\///;
    my $rest = $dict{$id};
    if (!defined $rest) {
        die $id;
    }
    print join "\t", ($line, @$rest);
    print "\n";
}
close $fh;
