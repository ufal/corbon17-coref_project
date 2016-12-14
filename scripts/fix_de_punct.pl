#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Data::Printer;

my $form_dir = $ARGV[0];
my $lemma_dir = $ARGV[1];
my $new_lemma_dir = $ARGV[2];

foreach my $form_file (glob "$form_dir/*.txt") {
    my $lemma_file = $form_file;
    $lemma_file =~ s/$form_dir/$lemma_dir/g;
    my $new_lemma_file = $form_file;
    $new_lemma_file =~ s/$form_dir/$new_lemma_dir/g;
    #p $form_file;
    #p $lemma_file;
    #p $new_lemma_file;

    open my $form_fh, "<:utf8", $form_file;
    open my $lemma_fh, "<:utf8", $lemma_file;
    open my $new_lemma_fh, ">:utf8", $new_lemma_file;

    while (my $form_line = <$form_fh>) {
        my $lemma_line = <$lemma_fh>;
        chomp $form_line;
        my ($form_id, $form_en, $form_de) = split /\t/, $form_line;
        my @forms = split / /, $form_de;
        chomp $lemma_line;
        my ($lemma_id, $lemma_en, $lemma_de) = split /\t/, $lemma_line;
        my @lemmas = split / /, $lemma_de;

        my @new_lemmas = map { $lemmas[$_] eq "--" ? $forms[$_] : $lemmas[$_] } 0..$#lemmas;

        print {$new_lemma_fh} join("\t", $lemma_id, $lemma_en, join(" ", @new_lemmas))."\n";
    }
    close $form_fh;
    close $lemma_fh;
    close $new_lemma_fh;
}
