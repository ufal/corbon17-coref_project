package Treex::Tool::Coreference::Features::RU_DE::AllMonolingual;

use Moose;
use Treex::Core::Common;
use List::MoreUtils qw/all any/;

extends 'Treex::Tool::Coreference::Features::AllMonolingual';

my $UNDEF_VALUE = "undef";
my $b_true = 1;
my $b_false = 0;


########################## MAIN METHODS ####################################

augment '_unary_features' => sub {
    my ($self, $node, $type) = @_;
    
    my $feats = {};
    $self->cs_morphosyntax_unary_feats($feats, $node, $type);

    my $sub_feats = inner() || {};
    return { %$feats, %$sub_feats };
};

override '_binary_features' => sub {
    my ($self, $set_feats, $anaph, $cand, $candord) = @_;
    my $feats = super();
    
    $self->cs_morphosyntax_binary_feats($feats, $set_feats, $anaph, $cand, $candord);
    return $feats;
};


################## MORPHO-(DEEP)SYNTAX FEATURES ####################################

sub cs_morphosyntax_unary_feats {
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

sub cs_morphosyntax_binary_feats {
    my ($self, $feats, $set_feats, $anaph, $cand, $candord) = @_;
    my @names = qw/
        apos asubpos agen anum acase apossgen apossnum apers
    /;
    foreach my $name (@names) {
        $feats->{"agree_$name"} = $self->_agree_feats($set_feats->{"c^cand_$name"}, $set_feats->{"a^anaph_$name"});
        $feats->{"join_$name"} = $self->_join_feats($set_feats->{"c^cand_$name"}, $set_feats->{"a^anaph_$name"});
    }
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
