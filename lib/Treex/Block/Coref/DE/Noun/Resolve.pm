package Treex::Block::Coref::DE::Noun::Resolve;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Coref::Resolve';
with 'Treex::Block::Coref::DE::Noun::Base';

#use Treex::Tool::Coreference::PerceptronRanker;
#use Treex::Tool::Coreference::RuleBasedRanker;
#use Treex::Tool::Coreference::ProbDistrRanker;
use Treex::Tool::ML::VowpalWabbit::Ranker;

override 'build_model_path' => sub {
    my $path = "/home/mnovak/projects/coref_projection/treex_cr_train/de/noun/tmp/ml/";
    # all NPs as anaphor candidates
    # BEST TRAIN
    #my $path = '/home/mnovak/projects/coref_projection/treex_cr_train/de/noun/tmp/ml/009_run_2017-01-22_00-08-33_5992.models_retrained_after_bugfix_in_a2t_mention_projection/001.8ba2e.mlmethod/model/train.official.table.gz.vw.ranking.model';
    # BIG TRAIN
    #my $path = '/home/mnovak/projects/coref_projection/treex_cr_train/de/noun/tmp/ml/010_run_2017-01-26_05-41-08_30982.models_retrained_on_big_train_set/001.8ba2e.mlmethod/model/big_train.official.table.gz.vw.ranking.model';
    # TRAIN AFTER PRONFIX
    #my $path = '/home/mnovak/projects/coref_projection/treex_cr_train/de/noun/tmp/ml/011_run_2017-01-27_00-16-58_26763.after_pronfix.train/001.8ba2e.mlmethod/model/train.official.table.gz.vw.ranking.model';
    # TRAIN-SMALL_DEV
    $path .= "012_run_2017-01-28_06-28-51_10251.on_train-small_dev/001.8ba2e.mlmethod/model/train-small_dev.official.table.gz.vw.ranking.model";
    print STDERR "MODEL_PATH: $path\n";
    return $path;
    # non-indefinite NPs as anaphor candidates
    #return '/home/mnovak/projects/coref_projection/treex_cr_train/de/noun/tmp/ml/003_run_2017-01-03_17-40-10_13275.run_on_DE_non-indefinite_nouns/001.8ba2e.mlmethod/model/train.official.table.gz.vw.ranking.model';
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

Treex::Block::Coref::DE::Noun::Resolve

=head1 DESCRIPTION

Pronoun coreference resolver for German.
Settings:
* German personal pronoun filtering of anaphor
* candidates for the antecedent are nouns from current (prior to anaphor) and previous sentence
* German pronoun coreference feature extractor
* using a model trained by a VW ranker

=head1 AUTHORS

Michal Novák <mnovak@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011-2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
