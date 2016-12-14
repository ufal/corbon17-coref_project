package Treex::Block::Coref::Load::SemEval2010;
use Moose;
use Treex::Core::Common;
use Data::Printer;
use List::MoreUtils qw/uniq/;
use Treex::Block::W2A::EN::Tokenize;
use Treex::Block::W2A::RU::Tokenize;
use Treex::Block::W2A::DE::Tokenize;

extends 'Treex::Core::Block';

has 'from_pattern' => ( 
    is => 'ro', 
    isa => 'Str', 
    required => 1, 
    documentation => 'A pattern of the path to search for the file to be loaded. The placeholder <BASE> is substituted with 
        the actual input file\'s basename (without its extension)',
);

sub _extract_coref_info {
    my ($coref_info_str) = @_;
    return ([], []) if ($coref_info_str eq '-');
    my @coref_info = split /\|/, $coref_info_str;
    my @start_idxs = map {$_ =~ /\((\d+)/; $1} grep {$_ =~ /\(\d+/} @coref_info;
    my @end_idxs = map {$_ =~ /(\d+)\)/; $1} grep {$_ =~ /\d+\)/} @coref_info;
    return (\@start_idxs, \@end_idxs);
}

sub _build_annotation {
    my ($self, $doc) = @_;

    my $from = $self->from_pattern;
    my $base = $doc->file_stem;
    $from =~ s/<BASE>/$base/g;

    # the format of @annotations is as follows:
    # [ #sentences
    #   [ #sentence_1
    #       [ 'form1', [ #start_entities 1, 2], [ #end_entities 3, 2] ],
    #       ...
    #   ],
    #   ...
    # ]
    my @annotation = ();
    my @curr_sent;

    my $lang = $self->language;
    my $tokenizer = ($lang eq "en") ? Treex::Block::W2A::EN::Tokenize->new() :
        ($lang eq "ru") ? Treex::Block::W2A::RU::Tokenize->new() :
        ($lang eq "de") ? Treex::Block::W2A::DE::Tokenize->new() : undef;

    open my $from_fh, "<:utf8", $from;
    while (<$from_fh>) {
        chomp $_;
        next if ($_ =~ /^\#/);
        if ($_ =~ /^\s*$/) {
            next if (!@curr_sent);
            push @annotation, [ @curr_sent ];
            @curr_sent = ();
        }
        else {
            my @cols = split /\t/, $_;
            # store only the form (col 3) and extract start and end from the coref info (col 11)
            my ($start_l, $end_l) = _extract_coref_info($cols[11]);
            if (defined $tokenizer) {
                my $wordstr = $cols[3];
                $wordstr =~ s/-LRB-/(/g;
                $wordstr =~ s/-RRB-/)/g;
                $wordstr =~ s/''/``/g;
                $wordstr = $tokenizer->tokenize_sentence($wordstr);
                my @words = split /\s/, $wordstr;

                # if a CoNLL token in split into several tokens, put the starts of mentions to the first token,
                # whereas the ends of mentions to the last token
                foreach my $w_idx (0 .. $#words) {
                    push @curr_sent, [$words[$w_idx], ($w_idx == 0 ? $start_l : []), ($w_idx == $#words ? $end_l : [])];
                }
            }
            else {
                push @curr_sent, [$cols[3], $start_l, $end_l];
            }
        }
    }

    return @annotation;
}

sub process_document {
    my ($self, $doc) = @_;
    my @annot = $self->_build_annotation($doc);

    my @atrees = map {$_->get_tree($self->language, 'a', $self->selector)} $doc->get_bundles;
    foreach my $atree (@atrees) {
        my @annot_sent = @{ shift @annot };

        _process_sentence($atree, @annot_sent);
        
    }
}


sub _process_sentence {
    my ($atree, @conll_sent) = @_;

    my @anodes = $atree->get_descendants({ordered => 1});
    
    my $j = 0;
    for (my $i = 0; $i < @anodes; $i++) {
        my $eq = 0;

        my $w_size = 10;
        my ($iws, $jws) = ($i, $j);
        my $iwe = $i + $w_size;
        my $jwe = $j + $w_size;
        while ($i < @anodes && $i < $iwe) {
            $j = $jws;
            while ($j < @conll_sent && $j < $jwe) {
                #printf STDERR "%s %s\n", $anodes[$i]->form, $conll_sent[$j]->[0];
                my $form = $anodes[$i]->form;
                $form =~ s/''/``/g;
                $eq = ($form eq $conll_sent[$j]->[0]);
                last if ($eq);
                $j++;
            }
            last if ($eq);
            $i++;
        }
        if ($eq || ($i == @anodes && $j == @conll_sent)) {
            if ($j > $jws || $i > $iws) {
                #printf STDERR "%d-%d -> %d-%d\n", $jws, $j-1, $iws, $i-1;
                #printf STDERR "CONLL: %s\n", join(" ", map {$_->[0]} @conll_sent[$jws .. $j-1]);
                #printf STDERR "ANODES: %s\n", join(" ", map {$_->form} @anodes[$iws .. $i-1]);
            }
            my @coref_starts = map {@{$_->[1]}} @conll_sent[$jws .. $j-1];
            my @coref_ends = map {@{$_->[2]}} @conll_sent[$jws .. $j-1];
            for (my $k = $iws; $k < $i; $k++) {
                set_coref_mention_wilds($anodes[$k], \@coref_starts, \@coref_ends);
            }
            if ($i < @anodes && $j < @conll_sent) {
                set_coref_mention_wilds($anodes[$i], $conll_sent[$j]->[1], $conll_sent[$j]->[2]);
            }
        }
        else {
            log_fatal "Too different.";
        }
        $j++;
    }

    #my @anode_prints = map {$_->form . "/". (join ",",@{$_->wild->{coref_mention_start} // []}) . "/" . (join ",",@{$_->wild->{coref_mention_end} // []}) } @anodes;
    #print STDERR join " ", @anode_prints;
    #print STDERR "\n";
    _make_entities_well_formed(\@anodes);
}

sub set_coref_mention_wilds {
    my ($anode, $coref_starts, $coref_ends) = @_;
    $anode->wild->{coref_mention_start} = $coref_starts if (@$coref_starts);
    $anode->wild->{coref_mention_end} = $coref_ends if (@$coref_ends);
}

sub _make_entities_well_formed {
    my ($anodes) = @_;
    _adjust_closing_brackets($anodes);
    _adjust_closing_brackets($anodes, 1);
}

sub _adjust_closing_brackets {
    my ($anodes, $reverse) = @_;
    
    my ($s, $e) = $reverse ? qw/end start/ : qw/start end/;
    my @anodes_ordered = $reverse ? reverse @$anodes : @$anodes;
    
    my @stack = ();
    foreach my $anode (@anodes_ordered) {
        #print STDERR $anode->form . " " . $anode->get_address."\n";
        my $start_ents = $anode->wild->{"coref_mention_$s"} // [];
        #log_info "START_ENTS: ".(np $start_ents);
        my $end_ents = $anode->wild->{"coref_mention_$e"} // [];
        #log_info "END_ENTS: ".(np $end_ents);
        if (defined $start_ents) {
            push @stack, $start_ents;
        }
        if (defined $end_ents) {
            # remembering also the frequency, because of the nested mentions of the same entity (10|(10...10)...10)
            my %end_ents_h; $end_ents_h{$_}++ foreach @$end_ents;
            my @ordered_end_ents = ();
            while (keys %end_ents_h) {
                my $top = pop @stack;
                my @new_top = @$top;
                foreach my $top_item (@$top) {
                    if (defined $end_ents_h{$top_item}) {
                        $end_ents_h{$top_item}--;
                        delete $end_ents_h{$top_item} if (!$end_ents_h{$top_item});
                        push @ordered_end_ents, $top_item;
                        # removing only the first occurrence with splice, because of the nested mentions of the same entity (10|(10...10)...10)
                        my $first_idx = first {$new_top[$_] eq $top_item} 0..$#new_top;
                        splice @new_top, $first_idx, 1;
                    }
                }
                #print STDERR "TOP, NEW_TOP:\n";
                #p @$top;
                #p @new_top;
                log_fatal "Not context-free for anode: ".$anode->get_address if (scalar(@$top) == scalar(@new_top) && scalar(@new_top) > 0);
                push @stack,  [ @new_top ] if (@new_top);
            }
            $anode->wild->{"coref_mention_$e"} = [ $reverse ? reverse @ordered_end_ents : @ordered_end_ents ] if (@ordered_end_ents);
            #print STDERR "CM_$e: ";
            #p $anode->wild->{"coref_mention_$e"};
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::Coref::Load::SemEval2010

=head1 DESCRIPTION

A block to import coreference annotated in SemEval2010 (CoNLL) style.
Several not very transparent adjustments must have been done to align
the tokenization within the a-trees and tokenization in the CoNLL files.


=head1 AUTHOR

Michal Novák <mnovak@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
