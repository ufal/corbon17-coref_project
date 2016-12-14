package Treex::Block::Coref::Project::MentionsOverAlayer;
use Moose;
use Treex::Core::Common;
use Data::Printer;

extends 'Treex::Core::Block';

has 'language' => ( is => 'ro', isa => 'Str', required => 1 );
has 'selector' => ( is => 'ro', isa => 'Str', required => 1 );
has 'to_language' => ( is => 'ro', isa => 'Str', required => 1 );
has 'to_selector' => ( is => 'ro', isa => 'Str', required => 1 );

sub process_atree {
    my ($self, $atree) = @_;
    my $all_mentions_count = 0;
    my $projected_mentions_count = 0;
    my @stack = ();
    foreach my $anode ($atree->get_descendants({ordered => 1})) {

        my @start_ents = @{$anode->wild->{coref_mention_start} // []};
        my @end_ents = @{$anode->wild->{coref_mention_end} // []};
        next if (!@start_ents && !@end_ents);
    
        my ($to_nodes, $to_types) = $anode->get_undirected_aligned_nodes({language => $self->to_language, selector => $self->to_selector});
        my ($to_node, @to_rest) = @$to_nodes;
        if (!defined $to_node) {
            log_info "No alignment of a coref node: ".$anode->get_address;
        }
        elsif (@to_rest) {
            log_info "Multiple alignment of a coref node: ".$anode->get_address;
            $to_node = undef;
        }
        
        foreach my $start_ent (@start_ents) {
            push @stack, [ $start_ent, $to_node ];
        }
        foreach my $end_ent (@end_ents) {
            my $top = pop @stack;
            my ($start_ent, $start_to_node) = @$top;
            if ($start_ent != $end_ent) {
                log_fatal "Coref mentions are not context-free: ".$anode->get_address;
            }
            $all_mentions_count++;
            next if (!defined $start_to_node || !defined $to_node);
            if ($start_to_node->ord <= $to_node->ord) {
                my $start_list = $start_to_node->wild->{coref_mention_start} // [];
                push @$start_list, $end_ent;
                $start_to_node->wild->{coref_mention_start} = $start_list;
                my $end_list = $to_node->wild->{coref_mention_end} // [];
                push @$end_list, $end_ent;
                $to_node->wild->{coref_mention_end} = $end_list;
                $projected_mentions_count++;
            }
            else {
                log_info "Alignment changes order: ".$anode->get_address;
            }
        }
    }
    print STDERR "Projected mentions: $projected_mentions_count / $all_mentions_count\n";
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
