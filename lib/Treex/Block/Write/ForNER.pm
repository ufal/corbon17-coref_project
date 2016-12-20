package Treex::Block::Write::ForNER;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::Write::BaseTextWriter';

has '+extension' => ( default => '.txt' );

sub process_atree {
    my ($self, $atree) = @_;
    foreach my $anode ($atree->get_descendants({ordered => 1})) {
        print {$self->_file_handle} join " ", ($anode->form, $anode->lemma, $anode->tag);
        print {$self->_file_handle} "\t".$anode->wild->{ner_tag}."\n";
    }
    print {$self->_file_handle} "\n";
}

1;
