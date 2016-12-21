package Treex::Tool::Coreference::Features::RU::Noun;

use Moose;
use Treex::Core::Common;
use List::MoreUtils qw/uniq/;
use Text::Levenshtein qw(distance);

extends 'Treex::Tool::Coreference::Features::RU::AllMonolingual';

my $UNDEF_VALUE = "undef";
my $b_true = 1;
my $b_false = 0;


########################## MAIN METHODS ####################################

augment '_unary_features' => sub {
    my ($self, $node, $type) = @_;
    
    my $feats = {};
    $self->wordeq_unary_feats($feats, $node, $type);
    $self->ne_unary_feats($feats, $node, $type);

    my $sub_feats = inner() || {};
    return { %$feats, %$sub_feats };
};

override '_binary_features' => sub {
    my ($self, $set_feats, $anaph, $cand, $candord) = @_;
    my $feats = super();
    
    $self->wordeq_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    $self->ne_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    return $feats;
};


################## WORD EQUALITY AND SIMILARITY FEATURES ####################################

sub wordeq_unary_feats {
    my ($self, $feats, $node, $type) = @_;
    $feats->{full_np_set} = join "_", (uniq sort map {$_->t_lemma} $node->get_descendants({add_self => 1, ordered => 1}));
}

sub wordeq_binary_feats {
    my ($self, $feats, $set_feats, $anaph, $cand, $candord) = @_;
    $feats->{agree_lemma} = $self->_agree_feats($set_feats->{"c^cand_lemma"}, $set_feats->{"a^anaph_lemma"});
    $feats->{join_lemma} = $self->_join_feats($set_feats->{"c^cand_lemma"}, $set_feats->{"a^anaph_lemma"});
    $feats->{dist_lemma} = distance($set_feats->{"c^cand_lemma"}, $set_feats->{"a^anaph_lemma"});
    
    $feats->{agree_full_np_set} = $self->_agree_feats($set_feats->{"c^cand_full_np_set"}, $set_feats->{"a^anaph_full_np_set"});
    $feats->{join_full_np_set} = $self->_join_feats($set_feats->{"c^cand_full_np_set"}, $set_feats->{"a^anaph_full_np_set"});
    $feats->{dist_full_np_set} = distance($set_feats->{"c^cand_full_np_set"}, $set_feats->{"a^anaph_full_np_set"});
}

######################### NAMED ENTITY FEATURES ###############################################

sub ne_unary_feats {
    my ($self, $feats, $node, $type) = @_;
    my $nnode = $node->get_n_node;
    $feats->{is_ne} = defined $nnode ? $b_true : $b_false;
    return if (!defined $nnode);
    $feats->{ne_type} = $nnode->ne_type;
    $feats->{ne_normname} = $nnode->normalized_name;
}

sub ne_binary_feats {
    my ($self, $feats, $set_feats, $anaph, $cand, $candord) = @_;
    $feats->{agree_is_ne} = $self->_agree_feats($set_feats->{"c^cand_is_ne"}, $set_feats->{"a^anaph_is_ne"});
    $feats->{join_is_ne} = $self->_join_feats($set_feats->{"c^cand_is_ne"}, $set_feats->{"a^anaph_is_ne"});
    $feats->{agree_ne_type} = $self->_agree_feats($set_feats->{"c^cand_ne_type"}, $set_feats->{"a^anaph_ne_type"});
    $feats->{join_ne_type} = $self->_join_feats($set_feats->{"c^cand_ne_type"}, $set_feats->{"a^anaph_ne_type"});
    $feats->{agree_ne_normname} = $self->_agree_feats($set_feats->{"c^cand_ne_normname"}, $set_feats->{"a^anaph_ne_normname"});
    $feats->{join_ne_normname} = $self->_join_feats($set_feats->{"c^cand_ne_normname"}, $set_feats->{"a^anaph_ne_normname"});
    return if (!defined $set_feats->{"c^cand_ne_normname"} || !defined $set_feats->{"a^anaph_ne_normname"});
    $feats->{dist_ne_normname} = distance($set_feats->{"c^cand_ne_normname"}, $set_feats->{"a^anaph_ne_normname"});
}

1;
__END__

=encoding utf-8

=head1 NAME 

Treex::Tool::Coreference::RU::PronCorefFeatures

=head1 DESCRIPTION

Features needed in Russian personal pronoun coreference resolution.

=head1 METHODS

=over

#=item _build_feature_names 
#
#Builds a list of features required for training/resolution.

=item _unary_features

It returns a hash of unary features that relate either to the anaphor or the
antecedent candidate.

Enriched with language-specific features.

=item _binary_features 

It returns a hash of binary features that combine both the anaphor and the
antecedent candidate.

Enriched with language-specific features.

=back

=head1 AUTHORS

Michal Novák <mnovak@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
