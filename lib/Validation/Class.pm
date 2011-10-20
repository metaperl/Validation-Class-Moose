use strict;
use warnings;

package Validation::Class;

use Validation::Class::Sugar ();
use Moose::Exporter;

my ($import, $unimport, $init_meta) = Moose::Exporter->build_import_methods(
    also             => 'Validation::Class::Sugar',
    base_class_roles => ['Validation::Class::Validator'],
);

sub import {
    return unless $import;
    goto &$import;
}


sub unimport {
    return unless $unimport;
    goto &$unimport;
}

sub init_meta {
    my ($dummy, %opts) = @_;
    Moose->init_meta(%opts);
    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $opts{for_class},
        roles => ['Validation::Class::Validator']
    );
    return Class::MOP::class_of($opts{for_class});
}

1;