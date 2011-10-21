# DSL For Defining Input Validation Rules

use strict;
use warnings;

package Validation::Class::Sugar;

# VERSION

use Scalar::Util qw(blessed);
use Carp qw(confess);

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

sub field {
    my ($meta, %spec) = @_;
    my $config = $meta->find_attribute_by_name('config');
    confess("config attribute not present") unless blessed($config);

    if (%spec) {
        my $name = ( keys(%spec) )[0];
        my $data = ( values(%spec) )[0];

        my $CFG = $config->{default}->();
           $CFG->{FIELDS}->{$name} = $data;
           $CFG->{FIELDS}->{$name}->{errors} = [];
           
        $config->{default} = sub {
            return $CFG
        }
    }

    return 'field', %spec;
}

sub mixin {
    my ($meta, %spec) = @_;
    my $config = $meta->find_attribute_by_name('config');
    confess("config attribute not present") unless blessed($config);

    if (%spec) {
        my $name = ( keys(%spec) )[0];
        my $data = ( values(%spec) )[0];

        my $CFG = $config->{default}->();
           $CFG->{MIXINS}->{$name} = $data;
           
        $config->{default} = sub {
            return $CFG
        }
    }

    return 'mixin', %spec;
}

sub filter {
    my ($meta, $name, $data) = @_;
    my $config = $meta->find_attribute_by_name('config');
    confess("config attribute not present") unless blessed($config);

    if ($name && ref $data) {
        
        my $CFG = $config->{default}->();
           $CFG->{FILTERS}->{$name} = $data;
        
        $config->{default} = sub {
            return $CFG
        }
    }

    return 'filter', $name, $data;
}

sub directive {
    my ($meta, $name, $data) = @_;
    my $config = $meta->find_attribute_by_name('config');
    confess("config attribute not present") unless blessed($config);

    if ($name && $data) {
        
        my $CFG = $config->{default}->();
           $CFG->{DIRECTIVES}->{$name} = {
                mixin     => 1,
                field     => 1,
                validator => $data
           };
        
        $config->{default} = sub {
            return $CFG
        }   
    }

    return 'directive', $name, $data;
}

no Moose::Exporter;

1;