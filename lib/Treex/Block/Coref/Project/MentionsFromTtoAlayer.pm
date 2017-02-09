package Treex::Block::Coref::Project::MentionsFromTtoAlayer;
use Moose;
use Treex::Core::Common;
use Data::Printer;

extends 'Treex::Core::Block';

sub project_coref_from {
    my ($self, $tnode, $max_entity_num) = @_;

    my ($ante) = $tnode->get_coref_nodes;
    return $max_entity_num if (!defined $ante);

    my ($anaph_start, $anaph_end) = $self->get_mention_anodes($tnode);
    my ($ante_start, $ante_end) = $self->get_mention_anodes($ante, $anaph_start);
    return $max_entity_num if (!defined $anaph_start || !defined $anaph_end || !defined $ante_start || !defined $ante_end);

    my $anaph_entity_num = get_entity_num($anaph_start, $anaph_end);
    my $ante_entity_num = get_entity_num($ante_start, $ante_end);

    return $max_entity_num if (defined $anaph_entity_num && defined $ante_entity_num);
    if (defined $ante_entity_num) {
        set_entity_to_mention($anaph_start, $anaph_end, $ante_entity_num);
        my $mention = join " ", map {$_->form} ($anaph_start, $anaph_start->get_nodes_between($anaph_end), ($anaph_start != $anaph_end ? $anaph_end : ()) );
        log_info "Setting ante number $ante_entity_num to anaph mention: $mention";
    }
    elsif (defined $anaph_entity_num) {
        set_entity_to_mention($ante_start, $ante_end, $anaph_entity_num);
        my $mention = join " ", map {$_->form} ($ante_start, $ante_start->get_nodes_between($ante_end), ($ante_start != $ante_end ? $ante_end : ()) );
        log_info "Setting anaph number $anaph_entity_num to ante mention: $mention";
    }
    else {
        $max_entity_num++;
        set_entity_to_mention($anaph_start, $anaph_end, $max_entity_num);
        set_entity_to_mention($ante_start, $ante_end, $max_entity_num);
        my $anaph_mention = join " ", map {$_->form} ($anaph_start, $anaph_start->get_nodes_between($anaph_end), ($anaph_start != $anaph_end ? $anaph_end : ()) );
        my $ante_mention = join " ", map {$_->form} ($ante_start, $ante_start->get_nodes_between($ante_end), ($ante_start != $ante_end ? $ante_end : ()) );
        log_info "Setting new number $max_entity_num to anaph mention: $anaph_mention; and ante_mention: $ante_mention";
    }
    return $max_entity_num;
}

sub set_entity_to_mention {
    my ($start, $end, $entity_num) = @_;
    my $start_mentions = $start->wild->{coref_mention_start} // [];
    push @$start_mentions, $entity_num;
    $start->wild->{coref_mention_start} = $start_mentions;
    my $end_mentions = $end->wild->{coref_mention_end} // [];
    push @$end_mentions, $entity_num;
    $end->wild->{coref_mention_end} = $end_mentions;
}

sub get_entity_num {
    my ($start, $end) = @_;
    my $start_mentions = $start->wild->{coref_mention_start} // [];
    my $end_mentions = $end->wild->{coref_mention_end} // [];
    my ($ent_num) = grep { my $start_ent = $_; any {$_ == $start_ent} @$end_mentions } @$start_mentions;
    return $ent_num;
}

sub get_mention_anodes {
    my ($self, $tnode, $stop_node) = @_;

    my @mention_nodes = get_desc_no_verbal_subtree($tnode);

    my $head_mention = $mention_nodes[0];
    my $a_head_mention = $head_mention->get_lex_anode;
    return if (!defined $a_head_mention);
    log_info "HEAD: ".$a_head_mention->form;

    my @mention_anodes = grep {defined $_ && ($_ == $a_head_mention || $_->is_descendant_of($a_head_mention))}
        map { $_->get_anodes } @mention_nodes;
    @mention_nodes = sort {$a->ord <=> $b->ord} @mention_anodes;
    if (defined $stop_node && any {$_->get_zone == $stop_node->get_zone} @mention_nodes) {
        @mention_nodes = grep {$_->ord < $stop_node->ord} @mention_nodes;
    }
    return if (!@mention_nodes);

    if ($mention_nodes[-1]->form =~ /^[.,:]$/) {
        pop @mention_nodes;
    }
    return ($mention_nodes[0], $mention_nodes[-1]);
}

sub get_desc_no_verbal_subtree {
    my ($tnode) = @_;
    my @desc = ( $tnode );
    foreach my $kid ($tnode->get_children) {
        next if ((defined $kid->formeme && $kid->formeme =~ /^v/) || (defined $kid->gram_sempos && $kid->gram_sempos =~ /^v/));
        my @subdesc = get_desc_no_verbal_subtree($kid);
        push @desc, @subdesc;
    }
    return @desc;
}


sub process_document {
    my ($self, $doc) = @_;

    my $max_entity_num = 0;
    my @atrees = map {$_->get_tree($self->language, 'a', $self->selector)} $doc->get_bundles;

    foreach my $atree (@atrees) {
        foreach my $anode ($atree->get_descendants({ordered => 1})) {
            my @start_ents = @{$anode->wild->{coref_mention_start} // []};
            foreach my $ent_num (@start_ents) {
                $max_entity_num = $ent_num if ($ent_num > $max_entity_num);
            }
        }
    }
    
    my @ttrees = map {$_->get_tree($self->language, 't', $self->selector)} $doc->get_bundles;
    foreach my $ttree (@ttrees) {
        foreach my $tnode ($ttree->get_descendants({ordered => 1})) {
            $max_entity_num = $self->project_coref_from($tnode, $max_entity_num);
        }
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::Coref::Project::MentionsFromAtoTlayer

=head1 DESCRIPTION

A block to transfer coreference annotated as mentions and entities
using "coref_mention_start" and "coref_mention_end" wild attributes
from the a-layer to the PDT-like annotation of coreference on the
t-layer.

=head1 AUTHOR

Michal Novák <mnovak@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
