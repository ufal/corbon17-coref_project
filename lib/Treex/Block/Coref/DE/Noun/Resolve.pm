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
    # all NPs as anaphor candidates
    my $path = '/home/mnovak/projects/coref_projection/treex_cr_train/de/noun/tmp/ml/004_run_2017-01-19_00-32-19_27857.run_on_all_DE_nouns-better_tecto-w2v/001.8ba2e.mlmethod/model/train.official.table.gz.vw.ranking.model';
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
