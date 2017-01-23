package Treex::Block::Coref::RU::Noun::Resolve;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Coref::Resolve';
with 'Treex::Block::Coref::RU::Noun::Base';

#use Treex::Tool::Coreference::PerceptronRanker;
#use Treex::Tool::Coreference::RuleBasedRanker;
#use Treex::Tool::Coreference::ProbDistrRanker;
use Treex::Tool::ML::VowpalWabbit::Ranker;

override 'build_model_path' => sub {
    #default => '/home/mnovak/projects/coref_projection/treex_cr_train/ru/noun/tmp/ml/002_run_2016-12-19_21-58-15_9694.first_model_of_ru_nouns/002.e5ce78c10f.featset/002.4e1ae.mlmethod/model/train.official.table.gz.vw.ranking.model',
    my $path = '/home/mnovak/projects/coref_projection/treex_cr_train/ru/noun/tmp/ml/006_run_2017-01-22_19-48-21_30370.models_retrained_after_bugfix_in_a2t_mention_projection/001.8ba2e.mlmethod/model/train.official.table.gz.vw.ranking.model';
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

Treex::Block::Coref::RU::Noun::Resolve

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
