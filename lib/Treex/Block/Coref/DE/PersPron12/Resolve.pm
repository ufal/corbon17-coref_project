package Treex::Block::Coref::DE::PersPron12::Resolve;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Coref::Resolve';
with 'Treex::Block::Coref::DE::PersPron12::Base';

#use Treex::Tool::Coreference::PerceptronRanker;
#use Treex::Tool::Coreference::RuleBasedRanker;
#use Treex::Tool::Coreference::ProbDistrRanker;
use Treex::Tool::ML::VowpalWabbit::Ranker;

override 'build_model_path' => sub {
    my $path = "/home/mnovak/projects/coref_projection/treex_cr_train/de/perspron12/tmp/ml/";
    # TRAIN AFTER PRONFIX
    #my $path = '/home/mnovak/projects/coref_projection/treex_cr_train/de/perspron12/tmp/ml/001_run_2017-01-27_08-07-22_19244.after_pronfix.train/001.8ba2e.mlmethod/model/train.official.table.gz.vw.ranking.model';
    # TRAIN-SMALL_DEV
    $path .= "002_run_2017-01-28_01-31-42_20963.on_train-small_dev/001.8ba2e.mlmethod/model/train-small_dev.official.table.gz.vw.ranking.model";
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

Treex::Block::Coref::DE::PersPron12::Resolve

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
