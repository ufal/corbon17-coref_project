#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

binmode STDOUT, ":utf8";

my %pos_to_ner = ();

my $ann_f = $ARGV[1];
open my $ann_fh, "<:utf8", $ann_f;

while (<$ann_fh>) {
    chomp $_;
    my ($id, $type, $start, $end) = split /\s+/, $_;
#    die "Two entities start at position $start\n" if (defined $pos_to_ner{$start});
#    die "Two entities end at position $end\n" if (defined $pos_to_ner{$end});
    $pos_to_ner{$start} = "___".$type."__";
    $pos_to_ner{$end} = "__".$type."___";
}
close $ann_fh;

my $txt_f = $ARGV[0];
open my $txt_fh, "<:utf8", $txt_f;

my @all_lines = <$txt_fh>;
my $all_text = join "", @all_lines;

my $new_text = "";

my @all_chars = split //, $all_text;
for (my $i = 0; $i < @all_chars; $i++) {
    if (defined $pos_to_ner{$i}) {
        $new_text .= $pos_to_ner{$i};
    }
    $new_text .= $all_chars[$i];
    print STDERR $all_chars[$i].ord($all_chars[$i]);
}
close $txt_fh;

print $new_text;
