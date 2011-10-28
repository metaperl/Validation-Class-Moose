# DSL For Defining Input Validation Rules

use strict;
use warnings;

package Validation::Class::Sugar;

# VERSION

use Scalar::Util qw(blessed);
use Carp qw(confess);

use Moose::Role;
use Moose::Exporter;
use Module::Find;

Moose::Exporter->setup_import_methods(
    with_meta => [qw(
        field
        mixin
        filter
        directive
        load_classes
        load_plugins
    )]
);

sub directive {
    my ($meta, $name, $data) = @_;
    my $config = __get_config($meta);
    confess("config attribute not present") unless blessed($config);

    if ($name && $data) {
        
        my $CFG = $config->profile;
           $CFG->{DIRECTIVES}->{$name} = {
                mixin     => 1,
                field     => 1,
                validator => $data
           };
    }

    return 'directive', $name, $data;
}

sub field {
    my ($meta, %spec) = @_;
    my $config = __get_config($meta);
    confess("config attribute not present") unless blessed($config);

    if (%spec) {
        my $name = ( keys(%spec) )[0];
        my $data = ( values(%spec) )[0];

        my $CFG = $config->profile;
           $CFG->{FIELDS}->{$name} = $data;
           $CFG->{FIELDS}->{$name}->{errors} = [];
    }

    return 'field', %spec;
}

sub filter {
    my ($meta, $name, $data) = @_;
    my $config = __get_config($meta);
    confess("config attribute not present") unless blessed($config);

    if ($name && ref $data) {
        
        my $CFG = $config->profile;
           $CFG->{FILTERS}->{$name} = $data;
    }

    return 'filter', $name, $data;
}

sub load_classes {
    my ($meta, $parent) = @_;
    my $rels = $meta->find_attribute_by_name('relatives');
    my $rels_map = {};
    
    # load sub-validation classes
    foreach my $child (usesub $parent) {
        my $nickname = $child;
           $nickname =~ s/^$parent//; $nickname =~ s/^:://;
           $nickname =~ s/([a-z])([A-Z])/$1\_$2/g;
           
        $rels_map->{lc $nickname} = $child;
    }
    
    $rels->{default} = sub {
        return $rels_map;
    };
    
    return $rels_map;
}

sub load_plugins {
    my ($meta, $class, @plugins) = @_;
    my $plgs = $meta->find_attribute_by_name('plugins');
    
    foreach my $plugin (@plugins) {
        if ($plugin !~ /^\+/) {
            $plugin = "Validation::Class::Plugin::$plugin";
        }
        else {
            $plugin =~ s/^\+//;
        }
        
        my $file = $plugin; $file =~ s/::/\//g;
        require "$file.pm";
    }
    
    $plgs->{default} = sub { [@plugins] };
    
    return $plgs;
}

sub mixin {
    my ($meta, %spec) = @_;
    my $config = __get_config($meta);
    confess("config attribute not present") unless blessed($config);

    if (%spec) {
        my $name = ( keys(%spec) )[0];
        my $data = ( values(%spec) )[0];

        my $CFG = $config->profile;
           $CFG->{MIXINS}->{$name} = $data;
    }

    return 'mixin', %spec;
}

sub __get_config {
    my ($meta) = @_;
    my $config = $meta->find_attribute_by_name('config');
    unless ($config) {
        $config = $meta->add_attribute(
            'config',
            'is'    => 'rw',
            'isa'   => 'HashRef',
            'traits'=> ['Profile']
        );
        $config->{default} = sub {
            return $config->profile
        }
    }
    return $config;
}

no Moose::Exporter;

1;