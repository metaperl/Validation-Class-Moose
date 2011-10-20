use strict;
use warnings;

package Validation::Class::Sugar;

use Moose ('has');
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => [qw(
        field
        mixin
        filter
        directive
    )],
    also => 'Moose',
);

has config => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub {{
        FIELDS     => {},
        MIXINS     => {},
        FILTERS    => {},
        DIRECTIVES => {}
    }}
);

sub field {
    print "printing from field() provided by sugar\n";
}

sub mixin {
    print "printing from mixin() provided by sugar\n";
}

sub filter {
    print "printing from field() provided by sugar\n";
}

sub directive {
    print "printing from field() provided by sugar\n";
}

no Moose::Exporter;

1;