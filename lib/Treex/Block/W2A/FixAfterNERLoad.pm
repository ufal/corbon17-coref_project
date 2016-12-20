package Treex::Block::W2A::FixAfterNERLoad;
use Moose;
use Treex::Core::Common;

extends 'Treex::Core::Block';

sub process_document {
    my ($self, $doc) = @_;

    my @atrees = map {$_->get_tree($self->language, 'a', $self->selector)} $doc->get_bundles;

    my $curr_ner = "_";
    my $next_ner = "_";
    foreach my $atree (@atrees) {
        if ($next_ner ne "_") {
            log_warn "Entity $next_ner spanning across sentences in ".$atree->get_address;
            $next_ner =~ s/^I-/B-/;
        }
        foreach my $anode ($atree->get_descendants({ordered => 1})) {
            $curr_ner = $next_ner;
            my $form = $anode->form;
            if ($form =~ s/^___([A-Z]+)__//) {
                $curr_ner = "B-".$1;
                $next_ner = "I-".$1;
            }
            if ($form =~ s/__([A-Z]+)___$//) {
                $next_ner = "_";
            }
            $anode->wild->{ner_tag} = $curr_ner;
            $anode->set_form($form);
        }
    }

    my $move_tag;
    foreach my $atree (@atrees) {
        $move_tag = undef if (defined $move_tag);
        foreach my $anode ($atree->get_descendants({ordered => 1})) {
            next if (!defined $move_tag && ($anode->form !~ /^\s*$/ || $anode->wild->{ner_tag} !~ /^B-/));
            if (!defined $move_tag) {
                $move_tag = $anode->wild->{ner_tag};
            }
            elsif ($anode->form !~ /^\s*$/) {
                $anode->wild->{ner_tag} = $move_tag;
                $move_tag = undef;
            }
            elsif ($anode->wild->{ner_tag} =~ /^B-/) {
                $move_tag = $anode->wild->{ner_tag};
            }
        }
    }

    foreach my $atree (@atrees) {
        foreach my $anode ($atree->get_descendants({ordered => 1})) {
            log_warn "Bad in ".$anode->get_address if $anode->form =~ /__/;
            if ($anode->form =~ /^\s*$/) {
                $anode->remove;
            }
        }
    }
    
}

1;
