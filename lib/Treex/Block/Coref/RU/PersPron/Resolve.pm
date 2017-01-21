package Treex::Block::Coref::RU::PersPron::Resolve;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Coref::Resolve';
with 'Treex::Block::Coref::RU::PersPron::Base';

#use Treex::Tool::Coreference::PerceptronRanker;
#use Treex::Tool::Coreference::RuleBasedRanker;
#use Treex::Tool::Coreference::ProbDistrRanker;
use Treex::Tool::ML::VowpalWabbit::Ranker;

override 'build_model_path' => sub {
has '+model_path' => (
    #default => '/home/mnovak/projects/coref_projection/treex_cr_train/ru/perspron/tmp/ml/001_run_2016-12-18_15-35-37_8076.first_attempt_to_train_RU_model_for_persprons/006.6d08f24520.featset/002.22ec1.mlmethod/model/train.official.table.gz.vw.ranking.model',
    my $path = '/home/mnovak/projects/coref_projection/treex_cr_train/ru/perspron/tmp/ml/003_run_2016-12-27_13-16-03_4350.new_perspron_feats/001.8ba2e.mlmethod/model/train.official.table.gz.vw.ranking.model';
    print STDERR "MODEL_PATH: $path\n";
    return $path;
};

override '_build_ranker' => sub {
    my ($self) = @_;
#    my $ranker = Treex::Tool::Coreference::RuleBasedRanker->new();
#    my $ranker = Treex::Tool::Coreference::ProbDistrRanker->new(
#    my $ranker = Treex::Tool::Coreference::PerceptronRanker->new( 
    my $ranker = Treex::Tool::ML::VowpalWabbit::Ranker->new( 
        { model_path => $self->model_path } 
    );
    return $ranker;
};

1;

#TODO adjust documentation

__END__

=encoding utf-8

=head1 NAME 

Treex::Block::Coref::RU::PersPron::Resolve

=head1 DESCRIPTION

Pronoun coreference resolver for Russian.
Settings:
* Russian personal pronoun filtering of anaphor
* candidates for the antecedent are nouns from current (prior to anaphor) and previous sentence
* Russian pronoun coreference feature extractor
* using a model trained by a VW ranker

=head1 AUTHORS

Michal Novák <mnovak@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011-2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
