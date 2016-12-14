package Treex::Block::Read::CoNLLTokens;

use strict;
use warnings;
use Moose;
use Treex::Core::Common;
use File::Slurp;
extends 'Treex::Block::Read::BaseCoNLLReader';

sub next_document {
    my ($self) = @_;
    my $text = $self->next_document_text();
    return if !defined $text;

    my $document = $self->new_document();
    foreach my $tree ( split /\n\s*\n/, $text ) {
        my @tokens  = split( /\n/, $tree );
        # Skip empty sentences (if any sentence is empty at all,
        # typically it is the first or the last one because of superfluous empty lines).
        next unless(@tokens);
        my $bundle  = $document->create_bundle();
        # The default bundle id is something like "s1" where 1 is the number of the sentence.
        # If the input file is split to multiple Treex documents, it is the index of the sentence in the current output document.
        # But we want the input sentence number. If the Treex documents are later exported to one file again, the sentence ids should remain unique.
        my $sentid = $self->sent_in_file() + 1;
        my $sid = $self->sid_prefix().'s'.$sentid;
        $bundle->set_id($sid);
        $self->set_sent_in_file($sentid);
        my $zone    = $bundle->create_zone( $self->language, $self->selector );
        my $aroot   = $zone->create_atree();
        $aroot->set_id($sid.'/'.$self->language());
        #if ( $self->deprel_is_afun ) {
        #    $aroot->set_afun('AuxS');
        #}
        my @parents = (0);
        my @nodes   = ($aroot);
        my $sentence = "";
        my $sid_set = 0;
        foreach my $token (@tokens) {
            next if $token =~ /^\s*$/;
            next if $token =~ /^\s*\#/;
            my ( $id, $form ) = split( /\t/, $token );
            my $newnode = $aroot->create_child();
            $newnode->shift_after_subtree($aroot);
            $newnode->set_form($form);
            $sentence .= "$form " if(defined($form));
        }
        $sentence =~ s/\s+$//;
        $zone->set_sentence($sentence);
    }

    return $document;
}

1;

__END__

=head1 NAME

Treex::Block::Read::CoNLLTokens

=head1 DESCRIPTION

Document reader for CoNLL format.
Each token is on separated line in the following format:
ord<tab>form<tab>lemma<tab>cpos<tab>pos<tab>features<tab>head<tab>deprel
Sentences are separated with blank line.
The sentences are stored into L<bundles|Treex::Core::Bundle> in the
L<document|Treex::Core::Document>.

See L<http://ilk.uvt.nl/conll/#dataformat>.

=head1 ATTRIBUTES

=over

=item from

space or comma separated list of filenames

=item lines_per_doc

number of sentences (!) per document

=back

=head1 METHODS

=over

=item next_document

Loads a document.

=back

=head1 SEE

L<Treex::Block::Read::BaseTextReader>
L<Treex::Core::Document>
L<Treex::Core::Bundle>

=head1 AUTHOR

Michal Novák <mnovak@ufal.mff.cuni.cz>
David Mareček <marecek@ufal.mff.cuni.cz>
Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011-2013, 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
