package Treex::Block::Load::Sentences;
use Moose;
use Treex::Core::Common;

extends 'Treex::Core::Block';

has 'from_pattern' => ( 
    is => 'ro', 
    isa => 'Str', 
    required => 1, 
    documentation => 'A pattern of the path to search for the file to be loaded. The placeholder <BASE> is substituted with 
        the actual input file\'s basename (without its extension)',
);

sub process_document {
    my ($self, $doc) = @_;

    my @bundles = $doc->get_bundles;
    
    my $from = $self->from_pattern;
    my $base = $doc->file_stem;
    $from =~ s/<BASE>/$base/g;

    open my $from_fh, "<:utf8", $from;
    while (my $sent = <$from_fh>) {
        chomp $sent;
        my $bundle = shift @bundles;
        my $zone = $bundle->create_zone($self->language, $self->selector);
        $zone->set_sentence($sent);
    }
    close $from_fh;

    log_warn "Number of sentences does not match" if (@bundles);
}

1;

__END__

=encoding utf-8

=head1 NAME

Treex::Block::Load::Sentences

=head1 DESCRIPTION

A block to import sentences to a specified zone.

=head1 AUTHOR

Michal Novák <mnovak@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2016 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
