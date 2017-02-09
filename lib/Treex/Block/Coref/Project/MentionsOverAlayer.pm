package Treex::Block::Coref::Project::MentionsOverAlayer;
use Moose;
use Treex::Core::Common;
use Data::Printer;

extends 'Treex::Core::Block';

has 'language' => ( is => 'ro', isa => 'Str', required => 1 );
has 'selector' => ( is => 'ro', isa => 'Str', required => 1, default => '' );
has 'to_language' => ( is => 'ro', isa => 'Str', required => 1 );
has 'to_selector' => ( is => 'ro', isa => 'Str', required => 1, default => '' );

sub process_atree {
    my ($self, $atree) = @_;
    my $all_mentions_count = 0;
    my $projected_mentions_count = 0;
    my @stack = ();
    foreach my $anode ($atree->get_descendants({ordered => 1})) {

        my @start_ents = @{$anode->wild->{coref_mention_start} // []};
        my @end_ents = @{$anode->wild->{coref_mention_end} // []};
        next if (!@start_ents && !@end_ents);
        
        foreach my $start_ent (@start_ents) {
            push @stack, [ $start_ent, $anode ];
        }
        foreach my $end_ent (@end_ents) {
            my $top = pop @stack;
            my ($start_ent, $start_node) = @$top;
            if ($start_ent != $end_ent) {
                log_fatal "Coref mentions are not context-free: ".$anode->get_address;
            }
            $all_mentions_count++;
            my ($start_ali_node, $end_ali_node) = $self->find_aligned_mention($start_node, $anode);
            next if (!defined $start_ali_node || !defined $end_ali_node);
            
            my $start_list = $start_ali_node->wild->{coref_mention_start} // [];
            # build the enitity lists on a projected side to ensure well-formedness
            unshift @$start_list, $end_ent;
            $start_ali_node->wild->{coref_mention_start} = $start_list;
            my $end_list = $end_ali_node->wild->{coref_mention_end} // [];
            push @$end_list, $end_ent;
            $end_ali_node->wild->{coref_mention_end} = $end_list;
            $projected_mentions_count++;
        }
    }
    print STDERR "Projected mentions: $projected_mentions_count / $all_mentions_count\n";
}

sub _create_segments {
    my @nodes = @_;
    my @segments = ();
    my $curr_segment = [];
    my $last_ord;
    foreach my $ali_node (@nodes) {
        if (defined $last_ord && $ali_node->ord > $last_ord+1) {
            push @segments, $curr_segment;
            $curr_segment = [];
        }
        push @$curr_segment, $ali_node;
        $last_ord = $ali_node->ord;
    }
    push @segments, $curr_segment;
    return @segments;
}

sub find_aligned_mention {
    my ($self, $s_node, $e_node) = @_;

    my @nodes_between = $s_node->get_nodes_between($e_node);
    my %mention_ali_nodes_h = map {$_->id => $_} map {
            my ($an, $at) = $_->get_undirected_aligned_nodes({language => $self->to_language, selector => $self->to_selector});
            @$an
        } ($s_node, @nodes_between, $e_node);
    my @mention_ali_nodes = sort {$a->ord <=> $b->ord} values %mention_ali_nodes_h; 
    
    my @segments = _create_segments(@mention_ali_nodes);
    if (@segments == 1) {
        my @seg = @{$segments[0]};
        return ($seg[0], $seg[$#seg]);
    }
    elsif (@segments > 1) {
        my $srcentstr = "[" . (join " ", map {$_->form} ($s_node, @nodes_between, $s_node != $e_node ? $e_node : ())) . "]";
        my $segstr = "";
        for (my $i = 0; $i < @segments; $i++) {
            my @seg = @{$segments[$i]};
            if ($i > 0) {
                my @prev_seg = @{$segments[$i-1]};
                my @between_segs = $prev_seg[$#prev_seg]->get_nodes_between($seg[0]);
                $segstr .= " ".(join " ", map {$_->form} @between_segs);
            }
            $segstr .= " [".(join " ", map {$_->form} @seg)."]";
        }
        log_info $s_node->get_address."\t".$srcentstr."\t".$segstr;
        return;
    }
    else {
        return;
    }

    
    #my ($to_nodes, $to_types) = $anode->get_undirected_aligned_nodes({language => $self->to_language, selector => $self->to_selector});
    #    my ($to_node, @to_rest) = @$to_nodes;
    #    if (!defined $to_node) {
    #        log_info "No alignment of a coref node: ".$anode->get_address;
    #    }
    #    elsif (@to_rest) {
    #        log_info "Multiple alignment of a coref node: ".$anode->get_address;
    #        $to_node = undef;
    #    }
    #        
    #        if ($start_to_node->ord <= $to_node->ord) {
    #            my $start_list = $start_to_node->wild->{coref_mention_start} // [];
    #            # build the enitity lists on a projected side to ensure well-formedness
    #            unshift @$start_list, $end_ent;
    #            $start_to_node->wild->{coref_mention_start} = $start_list;
    #            my $end_list = $to_node->wild->{coref_mention_end} // [];
    #            push @$end_list, $end_ent;
    #            $to_node->wild->{coref_mention_end} = $end_list;
    #            $projected_mentions_count++;
    #        }
    #        else {
    #            log_info "Alignment changes order: ".$anode->get_address;
    #        }
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
