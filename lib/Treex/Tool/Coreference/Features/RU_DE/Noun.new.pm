package Treex::Tool::Coreference::Features::RU::Noun;

use Moose;
use Treex::Core::Common;
use List::MoreUtils qw/uniq/;
use Text::Levenshtein qw(distance);
use Treex::Tool::Coreference::NodeFilter;

extends 'Treex::Tool::Coreference::Features::BaseCorefFeatures';

my $UNDEF_VALUE = "undef";
my $b_true = 1;
my $b_false = 0;


########################## MAIN METHODS ####################################

augment '_unary_features' => sub {
    my ($self, $node, $type) = @_;
    
    my $feats = {};
    $feats->{id} = $node->get_address;
    
    my @nodetypes = Treex::Tool::Coreference::NodeFilter::get_types($node);
    $feats->{'t^type'} = \@nodetypes;
    
    $self->morphosyntax_unary_feats($feats, $node, $type);
    $self->location_feats($feats, $node, $type);    
    $self->hajic_morphosyntax_unary_feats($feats, $node, $type);
    $self->np_unary_feats($feats, $node, $type);

    my $sub_feats = inner() || {};
    return { %$feats, %$sub_feats };
};

override '_binary_features' => sub {
    my ($self, $set_feats, $anaph, $cand, $candord) = @_;
    my $feats = {};
    
    $self->distance_feats($feats, $set_feats, $anaph, $cand, $candord);
    $self->morphosyntax_binary_feats($feats, $set_feats, $anaph, $cand);
    $self->hajic_morphosyntax_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    $self->cs_np_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    return $feats;
};

################## LOCATION AND DISTANCE FEATURES ####################################

sub location_feats {
    my ($self, $feats, $node, $type) = @_;
    if ($type eq 'anaph') {
        $feats->{sentord} = $self->_categorize( $node->get_root->wild->{czeng_sentord}, [0, 1, 2, 3] );
        # a feature from (Charniak and Elsner, 2009)
        $feats->{charniak_loc} = $self->_anaph_loc_buck($node);
    }
}

sub distance_feats {
    my ($self, $feats, $set_feats, $anaph, $cand, $candord) = @_;
    $feats->{sent_dist} = $anaph->get_bundle->get_position - $cand->get_bundle->get_position;
    $feats->{clause_dist} = $self->_categorize( $anaph->wild->{aca_clausenum} - $cand->wild->{aca_clausenum}, [-2, -1, 0, 1, 2, 3, 7] );
    $feats->{deepord_dist} = $self->_categorize( $anaph->wild->{doc_ord} - $cand->wild->{doc_ord}, [1, 2, 3, 6, 15, 25, 40, 50] );
    $feats->{cand_ord} = $self->_categorize( $candord, [1, 2, 3, 5, 8, 11, 17, 22] );
    # a feature from (Charniak and Elsner, 2009)
    $feats->{charniak_dist} = $self->_ante_loc_buck($anaph, $cand, $feats->{sent_dist});
}

sub _anaph_loc_buck {
    my ($self, $anaph) = @_;
    return $self->_categorize( $anaph->ord, [0, 3, 5, 9] );
}

sub _ante_loc_buck {
    my ($self, $anaph, $cand, $sent_dist) = @_;

    my $pos = $cand->ord;
    if ($sent_dist == 0) {
        $pos = $anaph->ord - $cand->ord;
    }
    return $self->_categorize( $pos, [0, 3, 5, 9, 17, 33] );
}

################## MORPHO-(DEEP)SYNTAX FEATURES ####################################

#my %actants = map { $_ => 1 } qw/ACT PAT ADDR APP/;

sub morphosyntax_unary_feats {
    my ($self, $feats, $node, $type) = @_;
    
    my $anode = $node->get_lex_anode;
    $feats->{lemma} = defined $anode ? $anode->lemma : $UNDEF_VALUE;
    $feats->{afun}  = defined $anode ? $anode->afun : $UNDEF_VALUE;
    
    $feats->{tlemma} = $node->t_lemma;
    $feats->{fmm}  = $node->formeme;
    #$feats->{fun}  = $node->functor;
    #$feats->{akt}  = $actants{ $node->functor } ? $b_true : $b_false;
    #$feats->{subj}  = _is_subject($node);
    $feats->{coord} = ( $node->is_member ) ? $b_true : $b_false if ($type eq 'cand');
    #$feats->{pers} = $node->is_name_of_person ? $b_true : $b_false;
    _set_eparent_features($feats, $node, $type);

    # features copied from the extractor for relative pronouns
    # grammatemes
    $feats->{gen} = $node->gram_gender || $UNDEF_VALUE;
    $feats->{num} = $node->gram_number || $UNDEF_VALUE;
    for my $gen (qw/anim inan fem neut/) {
        $feats->{"gen_$gen"} = $feats->{gen} =~ /$gen/ ? 1 : 0;
    }

    # features copied from the extractor for reflexive pronouns
    $feats->{is_refl} = Treex::Tool::Coreference::NodeFilter::matches($node, ['reflpron']) ? 1 : 0 if ($type eq 'cand');
    $feats->{is_subj_for_refl}  = $self->_is_subject_for_refl($node) if ($type eq 'cand');

    # features focused on demonstrative pronouns
    if ($type eq 'anaph') {
        $feats->{is_neutsg} = ($feats->{gen_neut} && $feats->{num} =~ /sg/) ? 1 : 0;
        $feats->{has_relclause} = _is_extended_by_relclause($node) ? 1 : 0;
        $feats->{has_clause} = (any {($_->clause_number // 0) != ($node->clause_number // 0)} $node->get_echildren) ? 1 : 0;
        $feats->{kid_fmm} = [ grep {defined $_} map {$_->formeme} $node->get_echildren ];
        $feats->{fmm_epar_lemma} = ($feats->{epar_lemma} // "undef") . '_' . ($feats->{fmm} // "undef");
    }
}

sub hajic_morphosyntax_unary_feats {
    my ($self, $feats, $node, $type) = @_;
	
    my $anode = $node->get_lex_anode;
    my @names = qw/
        apos asubpos agen anum acase apossgen apossnum apers
    /;
    #print STDERR "OUTSIDE: ".$anode->tag." ".$anode->id."\n" if (defined $anode && defined $anode->tag && length($anode->tag) < 8);
    for (my $i = 0; $i < 8; $i++) {
        $feats->{$names[$i]} = (defined $anode && length($anode->tag)) ? substr($anode->tag, $i, 1) : $UNDEF_VALUE;
    }
}

sub hajic_morphosyntax_binary_feats {
    my ($self, $feats, $set_feats, $anaph, $cand, $candord) = @_;
    my @names = qw/
        apos asubpos agen anum acase apossgen apossnum apers
    /;
    foreach my $name (@names) {
        $feats->{"agree_$name"} = $self->_agree_feats($set_feats->{"c^cand_$name"}, $set_feats->{"a^anaph_$name"});
        $feats->{"join_$name"} = $self->_join_feats($set_feats->{"c^cand_$name"}, $set_feats->{"a^anaph_$name"});
    }
}

# returns the first eparent's functor, sempos, formeme, lemma, diathesis,
# and its diathesis combined with the candidate's functor
sub _set_eparent_features {
	my ($feats, $node, $type) = @_;
	my ($epar) = $node->get_eparents({or_topological => 1});
    return if (!$epar);

    #$feats->{epar_fun} = $epar->functor;
    $feats->{epar_sempos} = $epar->gram_sempos;
    $feats->{epar_fmm} = $epar->formeme;
    $feats->{epar_lemma} = $epar->t_lemma;
    $feats->{epar_diath} = $epar->gram_diathesis // "0";
    #$feats->{fun_epar_diath} = $feats->{epar_diath} . "_" . $feats->{fun};
}

sub _is_subject_for_refl {
    my ($self, $t_node) = @_;
    return ($t_node->formeme // '') =~ /^(n:1|n:subj|drop)$/;
}

################## WORD EQUALITY AND SIMILARITY FEATURES ####################################

sub np_unary_feats {
    my ($self, $feats, $node, $type) = @_;
    $feats->{full_np_set} = join " ", (uniq sort map {$_->t_lemma} $node->get_descendants());
}

sub np_binary_feats {
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
