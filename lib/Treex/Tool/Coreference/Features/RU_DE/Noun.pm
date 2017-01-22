package Treex::Tool::Coreference::Features::RU_DE::Noun;

use Moose;
use Treex::Core::Common;
use List::MoreUtils qw/uniq/;
use Text::Levenshtein qw(distance);
use Treex::Tool::Python::RunFunc;
use Treex::Tool::Coreference::NodeFilter::Noun;

extends 'Treex::Tool::Coreference::Features::RU_DE::AllMonolingual';

my $UNDEF_VALUE = "undef";
my $b_true = 1;
my $b_false = 0;

has 'word2vec_model' => ( is => 'ro', isa => 'Str', predicate => 'has_word2vec_model' );
has '_word2vec_python' => ( is => 'ro', isa => 'Maybe[Treex::Tool::Python::RunFunc]', builder => '_build_word2vec_python', lazy => 1 );

sub BUILD {
    my ($self) = @_;
    $self->_word2vec_python;
}

my $PYTHON_INIT = <<INIT;
import gensim
model = gensim.models.Word2Vec.load_word2vec_format("%s", binary=True)
print "OK"
INIT

sub _build_word2vec_python {
    my ($self) = @_;
    if ($self->has_word2vec_model) {
        my $cmd = sprintf $PYTHON_INIT, $self->word2vec_model;
        my $python = Treex::Tool::Python::RunFunc->new();
        my $out = $python->command($cmd);
        if ($out eq "OK") {
            return $python;
        }
        else {
            log_warn "The word2vec model cannot be loaded from: ".$self->word2vec_model."\nPython output: $out";
        }
    }
    return undef;
}


########################## MAIN METHODS ####################################

augment '_unary_features' => sub {
    my ($self, $node, $type) = @_;
    
    my $feats = {};
    $self->morpho_unary_feats($feats, $node, $type);
    $self->wordeq_unary_feats($feats, $node, $type);
    $self->ne_unary_feats($feats, $node, $type);

    my $sub_feats = inner() || {};
    return { %$feats, %$sub_feats };
};

override '_binary_features' => sub {
    my ($self, $set_feats, $anaph, $cand, $candord) = @_;
    my $feats = super();
    
    $self->morpho_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    $self->wordeq_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    $self->word2vec_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    $self->ne_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    return $feats;
};

override '_add_global_features' => sub {
    my ($self, $cands_feats, $anaph_feats, $cands, $anaph) = @_;
    super();
    $self->word2vec_global_feats($cands_feats, $anaph_feats, $cands, $anaph);
};

############################### MORPHO FEATURES #########################################

sub morpho_unary_feats {
    my ($self, $feats, $node, $type) = @_;
    my $anode = $node->get_lex_anode;
    if (defined $anode) {
        $feats->{def} = Treex::Tool::Coreference::NodeFilter::Noun::is_indefinite($anode) ? "indef" :
                        (Treex::Tool::Coreference::NodeFilter::Noun::is_definite($anode) ? "def" : 0);
    }
}

sub morpho_binary_feats {
    my ($self, $feats, $set_feats, $anaph, $cand, $candord) = @_;
    $feats->{agree_def} = $self->_agree_feats($set_feats->{"c^cand_def"}, $set_feats->{"a^anaph_def"});
    $feats->{join_def} = $self->_join_feats($set_feats->{"c^cand_def"}, $set_feats->{"a^anaph_def"});
}

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

    $feats->{agree_lemma_def} = $feats->{agree_lemma} . "_" . $feats->{join_def};
    $feats->{join_lemma_def} = $feats->{join_lemma} . "_" . $feats->{join_def};

    $feats->{agree_full_np_set} = $self->_agree_feats($set_feats->{"c^cand_full_np_set"}, $set_feats->{"a^anaph_full_np_set"});
    $feats->{join_full_np_set} = $self->_join_feats($set_feats->{"c^cand_full_np_set"}, $set_feats->{"a^anaph_full_np_set"});
    $feats->{dist_full_np_set} = distance($set_feats->{"c^cand_full_np_set"}, $set_feats->{"a^anaph_full_np_set"});
}

my $SIM_PYTHON_CMD = <<CMD;
try:
    print model.similarity('%s', '%s')
except KeyError:
    print "undef"
CMD

sub word2vec_binary_feats {
    my ($self, $feats, $set_feats, $anaph, $cand, $candord) = @_;

    my $cmd = "model.similarity('%s', '%s')\n";

    $cmd = sprintf $SIM_PYTHON_CMD, 
        _prepare_str_for_word2vec($set_feats->{"c^cand_lemma"}),
        _prepare_str_for_word2vec($set_feats->{"a^anaph_lemma"});
    my $python = $self->_word2vec_python;
    if (defined $python) {
        my $score = $self->_word2vec_python->command($cmd);
        $score = $self->_categorize( $score, [ map {$_ * 0.05} 0 .. 19 ] ) if ($score ne "undef");
        $feats->{word2vec_sim} = $score;
    }
}

sub _prepare_str_for_word2vec {
    my ($str) = @_;

    # escape \ and '
    $str =~ s/\\/\\\\/g;
    $str =~ s/'/\\'/g;

    # transform umlauts
    $str =~ s/ä/ae/g;
    $str =~ s/ö/oe/g;
    $str =~ s/ü/ue/g;
    $str =~ s/Ä/Ae/g;
    $str =~ s/Ö/Oe/g;
    $str =~ s/Ü/Ue/g;
    $str =~ s/ß/ss/g;

    return $str;
}

sub word2vec_global_feats {
    my ($self, $cands_feats, $anaph_feats, $cands, $anaph) = @_;
    my @word2vec_sims = grep {defined $_} map {$_->{word2vec_sim}} @$cands_feats;
    my @def_idxs = grep {$word2vec_sims[$_] ne "undef"} 0 .. $#word2vec_sims;
    my @order = sort {$word2vec_sims[$b] <=> $word2vec_sims[$a]} @def_idxs;
    my $i = 1;
    foreach my $ord (@order) {
        $cands_feats->[$ord]->{rank_word2vec_sim} = $self->_categorize( $i, [ 1, 2, 3, 5, 10 ]);
        $i++;
    }
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

Treex::Tool::Coreference::RU_DE::PronCorefFeatures

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
