package Treex::Block::Coref::RU::ReflPron::Base;
use Moose::Role;
use Treex::Core::Common;

use Treex::Tool::Coreference::AnteCandsGetter;
use Treex::Tool::Coreference::Features::RU_DE::AllMonolingual;

with 'Treex::Block::Coref::SupervisedBase' => {
    -excludes => [ '_build_feature_extractor', '_build_ante_cands_selector' ],
};

sub _build_node_types {
    return 'reflpron.no_poss';
}

#sub _build_feature_extractor {
#    my ($self) = @_;
#    return Treex::Tool::Coreference::Features::ReflPossPron->new();
#}

sub _build_feature_extractor {
    my ($self) = @_;
    my $fe = Treex::Tool::Coreference::Features::RU_DE::AllMonolingual->new();
    return $fe;
}

sub _build_ante_cands_selector {
    my ($self) = @_;
    my $acs = Treex::Tool::Coreference::AnteCandsGetter->new({
        cand_types => [ 'noun' ],
        prev_sents_num => 0,
        preceding_only => 0,
        cands_within_czeng_blocks => 1,
        max_size => 100,
    });
    return $acs;
}

1;

#TODO extend documentation

__END__

=head1 NAME

Treex::Block::Coref::RU::ReflPron::Base

=head1 RUSCRIPTION

This role is a basis for supervised coreference resolution of German personal pronouns.
Both the data printer and resolver should apply this role.

=head1 AUTHOR

Michal Novak <mnovak@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011-2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
