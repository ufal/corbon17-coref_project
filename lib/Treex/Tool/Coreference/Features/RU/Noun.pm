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
    $self->cs_np_unary_feats($feats, $node, $type);

    my $sub_feats = inner() || {};
    return { %$feats, %$sub_feats };
};

override '_binary_features' => sub {
    my ($self, $set_feats, $anaph, $cand, $candord) = @_;
    my $feats = super();
    
    $self->cs_np_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    return $feats;
};


################## MORPHO-(DEEP)SYNTAX FEATURES ####################################

sub cs_np_unary_feats {
    my ($self, $feats, $node, $type) = @_;
    $feats->{full_np_set} = join " ", (uniq sort map {$_->t_lemma} $node->get_descendants());
}

sub cs_np_binary_feats {
    my ($self, $feats, $set_feats, $anaph, $cand, $candord) = @_;
    $feats->{head_eq} = $set_feats->{"c^cand_lemma"} eq $set_feats->{"a^anaph_lemma"} ? 1 : 0;
    $feats->{head_dist} = distance($set_feats->{"c^cand_lemma"}, $set_feats->{"a^anaph_lemma"});
    $feats->{full_np_set_eq} = $set_feats->{"c^cand_full_np_set"} eq $set_feats->{"a^anaph_full_np_set"} ? 1 : 0;
    $feats->{full_np_set_dist} = distance($set_feats->{"c^cand_full_np_set"}, $set_feats->{"a^anaph_full_np_set"});
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
