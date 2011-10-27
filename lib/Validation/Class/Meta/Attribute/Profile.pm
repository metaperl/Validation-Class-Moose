# Base Configuration Profile for a Validation::Class Instance

use strict;
use warnings;

package Validation::Class::Meta::Attribute::Profile;

# VERSION

use Moose::Role;

has profile => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub {{
        FIELDS     => {},
        MIXINS     => {},
        FILTERS    => {
            alpha => sub {
                $_[0] =~ s/[^A-Za-z]//g;
                $_[0];
            },
            alphanumeric => sub {
                $_[0] =~ s/[^A-Za-z0-9]//g;
                $_[0];
            },
            capitalize => sub {
                $_[0] = ucfirst $_[0];
                $_[0] =~ s/\.\s+([a-z])/\. \U$1/g;
                $_[0];
            },
            decimal => sub {
                $_[0] =~ s/[^0-9\.\,]//g;
                $_[0];
            },
            lowercase => sub {
                lc $_[0];
            },
            numeric => sub {
                $_[0] =~ s/\D//g;
                $_[0];
            },
            strip => sub {
                $_[0] =~ s/\s+/ /g;
                $_[0] =~ s/^\s+//;
                $_[0] =~ s/\s+$//;
                $_[0];
            },
            titlecase => sub {
                join( " ", map ( ucfirst, split( /\s/, lc $_[0] ) ) );
            },
            trim => sub {
                $_[0] =~ s/^\s+//g;
                $_[0] =~ s/\s+$//g;
                $_[0];
            },
            uppercase => sub {
                uc $_[0];
            }
        },
        DIRECTIVES => {
            alias => {
                mixin => 0,
                field => 1,
                multi => 1
            },
            between => {
                mixin     => 1,
                field     => 1,
                multi     => 0,
                validator => sub {
                    my ($directive, $value, $field, $class) = @_;
                    my ($min, $max) = split /\-/, $directive;
                    
                    $min = scalar($min);
                    $max = scalar($max);
                    $value = length($value);
                    
                    if ($value) {
                        unless ($value >= $min && $value <= $max) {
                            my $handle = $field->{label} || $field->{name};
                            $class->error(
                                $field,
                                "$handle must contain between $directive characters"
                            );
                            return 0;
                        }
                    }
                    return 1;
                }
            },
            error => {
                mixin => 0,
                field => 1,
                multi => 0
            },
            errors => {
                mixin => 0,
                field => 1,
                multi => 0
            },
            filter => {
                mixin => 1,
                field => 1,
                multi => 1
            },
            filters => {
                mixin => 1,
                field => 1,
                multi => 1
            },
            label => {
                mixin => 0,
                field => 1,
                multi => 0
            },
            length => {
                mixin     => 1,
                field     => 1,
                multi     => 0,
                validator => sub {
                    my ($directive, $value, $field, $class) = @_;
                    
                    $value = length($value);
                    
                    if ($value) {
                        unless ($value == $directive) {
                            my $handle = $field->{label} || $field->{name};
                            my $characters = $directive > 1 ?
                            "characters" : "character";
                            
                            $class->error(
                                $field, "$handle must contain exactly "
                                ."$directive $characters"
                            );
                            return 0;
                        }
                    }
                    return 1;
                }
            },
            matches => {
                mixin     => 1,
                field     => 1,
                multi     => 0,
                validator => sub {
                    my ( $directive, $value, $field, $class ) = @_;
                    if ($value) {
                        # build the regex
                        my $password = $value;
                        my $password_confirmation = $class->params->{$directive} || '';
                        unless ( $password =~ /^$password_confirmation$/ ) {
                            my $handle  = $field->{label} || $field->{name};
                            my $handle2 = $class->fields->{$directive}->{label}
                                || $class->fields->{$directive}->{name};
                            my $error = "$handle does not match $handle2";
                            $class->error( $field, $error );
                            return 0;
                        }
                    }
                    return 1;
                }
            },
            max_length => {
                mixin     => 1,
                field     => 1,
                multi     => 0,
                validator => sub {
                    my ( $directive, $value, $field, $class ) = @_;
                    if ($value) {
                        unless ( length($value) <= $directive ) {
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "characters" : "character";
                            my $error = "$handle must contain "
                            ."$directive $characters or less";
                            
                            $class->error( $field, $error );
                            return 0;
                        }
                    }
                    return 1;
                }
            },
            min_length => {
                mixin     => 1,
                field     => 1,
                multi     => 0,
                validator => sub {
                    my ( $directive, $value, $field, $class ) = @_;
                    if ($value) {
                        unless ( length($value) >= $directive ) {
                            my $handle = $field->{label} || $field->{name};
                            my $characters = int( $directive ) > 1 ?
                                "characters" : "character";
                            my $error = "$handle must contain "
                            ."$directive or more $characters";
                            
                            $class->error( $field, $error );
                            return 0;
                        }
                    }
                    return 1;
                }
            },
            mixin => {
                mixin => 0,
                field => 1,
                multi => 1
            },
            mixin_field => {
                mixin => 0,
                field => 1,
                multi => 1
            },
            name => {
                mixin => 0,
                field => 1,
                multi => 0
            },
            options => {
                mixin     => 1,
                field     => 1,
                multi     => 0,
                validator => sub {
                    my ( $directive, $value, $field, $class ) = @_;
                    if ($value) {
                        # build the regex
                        my (@options) = split /\,\s?/, $directive;
                        unless ( grep { $value =~ /^$_$/ } @options ) {
                            my $handle  = $field->{label} || $field->{name};
                            my $error = "$handle must be " . join " or ", @options;
                            $class->error( $field, $error );
                            return 0;
                        }
                    }
                    return 1;
                }
            },
            pattern => {
                mixin     => 1,
                field     => 1,
                multi     => 0,
                validator => sub {
                    my ( $directive, $value, $field, $class ) = @_;
                    if ($value) {
                        # build the regex
                        my $regex = $directive;
                        $regex =~ s/([^#X ])/\\$1/g;
                        $regex =~ s/#/\\d/g;
                        $regex =~ s/X/[a-zA-Z]/g;
                        $regex = qr/$regex/;
                        unless ( $value =~ $regex ) {
                            my $handle = $field->{label} || $field->{name};
                            my $error = "$handle does not match the "
                            ."pattern $directive";
                            
                            $class->error( $field, $error );
                            return 0;
                        }
                    }
                    return 1;
                }
            },
            required => {
                mixin => 1,
                field => 1,
                multi => 0
            },
            validation => {
                mixin => 0,
                field => 1,
                multi => 0
            },
            value => {
                mixin => 1,
                field => 1,
                multi => 1
            }
        }
    }}
);

1;