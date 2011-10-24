# ABSTRACT: Input Validation and Parameter Handling Routines

use strict;
use warnings;

package Validation::Class::Validator;

# VERSION

use Moose::Role;
use Array::Unique;
use Hash::Flatten;

has config => (
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

# mixin/field types store
has 'directives' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { shift->config->{DIRECTIVES} }
);

# ignore unknown input parameters
has 'ignore_unknown' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

# validation rules store
has 'fields' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { shift->config->{FIELDS} },
);

# mixin/field types store
has 'filters' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { shift->config->{FILTERS} }
);

# nested hashref serializer
has 'hash_inflator' => (
    is      => 'rw',
    isa     => 'HashRef'
);

around 'hash_inflator' => sub {
    my $orig    = shift;
    my $self    = shift;
    my $options = shift || {
        hash_delimiter  => '.',
        array_delimiter => ':',
        escape_sequence => '',
    };
    
    foreach my $option (keys %{$options}) {
        if ($option =~ /\_/) {
            my $cc_option = $option;
            $cc_option =~ s/([a-zA-Z])\_([a-zA-Z])/$1\u$2/gi;
            $options->{ucfirst $cc_option} = $options->{$option};
            delete $options->{$option};
        }
    }

    return $self->$orig($options);
};

# validation rules templates store
has 'mixins' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { shift->config->{MIXINS} }
);

# input parameters store
has 'params' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

# report unknown input parameters
has 'report_unknown' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

# collection of field names to be used in validation
has 'stashed' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);

# mixin/field directives store
has 'types' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my  $self = shift;
        
        my  $types = {
            mixin => {},
            field => {}
        };
        
        my  $DIRECTIVES = $self->directives;
        
        foreach my $directive (keys %{ $DIRECTIVES }) {
            $types->{mixin}->{$directive} = $DIRECTIVES->{$directive}
                if $DIRECTIVES->{$directive}->{mixin};
            $types->{field}->{$directive} = $DIRECTIVES->{$directive}
                if $DIRECTIVES->{$directive}->{field};
        }
        
        return $types;
    }
);

# tie it all together after instantiation
sub BUILD {
    my $self = shift;
    
    # automatically serialize params if nested hash detected
    if (grep { ref($_) } values %{$self->params}) {
        $self->set_params_hash($self->params);
    }
    
    # reset fields if applicable
    $self->reset_fields();
    
    # add custom filters
    
        #foreach my $filter (keys %{$FILTERS}) {
        #    unless (defined $self->filters->{$filter}) {
        #        $self->filters->{$filter} = $FILTERS->{$filter};
        #    }
        #}

    # validate mixin directives
    foreach my $mixin ( keys %{ $self->mixins } ) {
        $self->check_mixin( $mixin, $self->mixins->{$mixin} );
    }

    # validate field directives and create filters arrayref if needed
    foreach my $field ( keys %{ $self->fields } ) {
        $self->check_field( $field, $self->fields->{$field} );
        
        if ( ! defined $self->fields->{$field}->{filters} ) {
            $self->fields->{$field}->{filters} = [];
        }
        
    }

    # check for and process a mixin directive
    foreach my $field ( keys %{ $self->fields } ) {
        

        $self->use_mixin( $field, $self->fields->{$field}->{mixin} )
            if $self->fields->{$field}->{mixin};
        
    }

    # check for and process a mixin_field directive
    foreach my $field ( keys %{ $self->fields } ) {
        

        $self->use_mixin_field( $self->fields->{$field}->{mixin_field}, $field )
          if $self->fields->{$field}->{mixin_field}
              && $self->fields->{ $self->fields->{$field}->{mixin_field} };
        
    }

    # check for and process input filters and default values
    foreach my $field ( keys %{ $self->fields } ) {
        
        tie my @filters, 'Array::Unique';
        @filters = @{ $self->fields->{$field}->{filters} };

        if ( defined $self->fields->{$field}->{filter} ) {
            
            push @filters,
                "ARRAY" eq ref $self->fields->{$field}->{filter} ?
                    @{$self->fields->{$field}->{filter}} :
                    $self->fields->{$field}->{filter} ;
            
            delete $self->fields->{$field}->{filter};
        }

        $self->fields->{$field}->{filters} = [@filters];

        foreach my $filter ( @{ $self->fields->{$field}->{filters} } ) {
            if ( defined $self->params->{$field} ) {
                $self->use_filter( $filter, $field );
            }
        }

        # default values
        if ( defined $self->params->{$field}
            && length( $self->params->{$field} ) == 0 )
        {
            if ( $self->fields->{$field}->{value} ) {
                $self->params->{$field} = $self->fields->{$field}->{value};
            }
        }
        
    }
    
    # alias checking, ... for duplicate aliases, etc
    my $fieldtree = {};
    my $aliastree = {};
    foreach my $field (keys %{$self->fields}) {
        $fieldtree->{$field} = $field;
        my $f = $self->fields->{$field};
        if (defined $f->{alias}) {
            my $aliases = "ARRAY" eq ref $f->{alias} ?
                $f->{alias} : [$f->{alias}];
            
            foreach my $alias (@{$aliases}) {
                if ($aliastree->{$alias}) {
                    die "The field $field contains the alias $alias which is ".
                        "also defined in the field $aliastree->{$alias}";
                }
                elsif ($fieldtree->{$alias}) {
                    die "The field $field contains the alias $alias which is ".
                        "the name of an existing field";
                }
                else {
                    $aliastree->{$alias} = $field;
                }
            }
        }
    }
    undef $aliastree;

    # always done last!!! auto-generate the field name
    # happens again at validation, FYI
    $self->fields->{$_}->{name} = $_ for ( keys %{ $self->fields } );

    return $self;
};

sub check_field {
    my ( $self, $field, $spec ) = @_;

    my $directives = $self->types->{field};

    foreach ( keys %{$spec} ) {
        if ( ! defined $directives->{$_} ) {
            my $death_cert =
              "The $_ directive supplied by the $field field is not supported";
            $self->_suicide_by_unknown_field($death_cert);
        }
    }

    return 1;
}

sub check_mixin {
    my ( $self, $mixin, $spec ) = @_;

    my $directives = $self->types->{mixin};

    foreach ( keys %{$spec} ) {
        if ( ! defined $directives->{$_} ) {
            my $death_cert =
              "The $_ directive supplied by the $mixin mixin is not supported";
            $self->_suicide_by_unknown_field($death_cert);
        }
        if ( ! $directives->{$_} ) {
            my $death_cert =
              "The $_ directive supplied by the $mixin mixin is empty";
            $self->_suicide_by_unknown_field($death_cert);
        }
    }

    return 1;
}

sub error {
    my ( $self, @params ) = @_;

    if ( @params == 2 ) {

        # set error message
        my ( $field, $error_msg ) = @params;
        if ( ref($field) eq "HASH" && ( !ref($error_msg) && $error_msg ) ) {
            if ( defined $self->fields->{ $field->{name} }->{error} ) {

                # temporary, may break stuff
                $error_msg = $self->fields->{ $field->{name} }->{error};

                push @{ $self->fields->{ $field->{name} }->{errors} },
                  $error_msg
                  unless grep { $_ eq $error_msg }
                      @{ $self->fields->{ $field->{name} }->{errors} };
                push @{ $self->{errors} }, $error_msg
                  unless grep { $_ eq $error_msg } @{ $self->{errors} };
            }
            else {
                push @{ $self->fields->{ $field->{name} }->{errors} },
                  $error_msg
                  unless grep { $_ eq $error_msg }
                      @{ $self->fields->{ $field->{name} }->{errors} };
                push @{ $self->{errors} }, $error_msg
                  unless grep { $_ eq $error_msg } @{ $self->{errors} };
            }
        }
        else {
            die "Can't set error without proper field and error message data, "
              . "field must be a hashref with name and value keys";
        }
    }
    elsif ( @params == 1 ) {

        # return param-specific errors
        return $self->fields->{ $params[0] }->{errors};
    }
    else {

        # return all errors
        return $self->{errors};
    }

    return 0;
}

sub error_fields {
    my ($self) = @_;
    my $error_fields = {};

    for my $field ( keys %{ $self->fields } ) {
        my $errors = $self->fields->{$field}->{errors};
        if ( @{$errors} ) {
            $error_fields->{$field} = $errors;
        }
    }

    return $error_fields;
}

sub get_params {
    my ($self, @params) = @_;
    
    return map {
        $self->params->{$_}
    }   @params;
}

sub get_params_hash {
    my ($self) = @_;
    my $serializer = Hash::Flatten->new($self->hash_inflator);
    my $params = $serializer->unflatten($self->params);
    
    return $params;
}

sub param {
    return defined $_[0]->params->{$_[1]} ? $_[0]->params->{$_[1]} : undef;
}

sub queue {
    my  ($self, @field_names) = @_;
    push @{$self->stashed}, @field_names if @field_names;
    return $self;
}

sub set_params_hash {
    my ($self, $params) = @_;
    my $serializer = Hash::Flatten->new($self->hash_inflator);
    
    return $self->params($serializer->flatten($params));
}

sub reset {
    my  $self = shift;
        $self->stashed([]);
        $self->reset_fields;
    return $self;
}

sub reset_errors {
    my $self = shift;
       $self->{errors} = [];
    
    for my $field ( keys %{ $self->fields } ) {
        $self->fields->{$field}->{errors} = [];
    }
}

sub reset_fields {
    my $self = shift;
       $self->reset_errors();
    
    for my $field ( keys %{ $self->fields } ) {
        delete $self->fields->{$field}->{value};
    }
    
    return $self;
}

sub use_filter {
    my ( $self, $filter, $field ) = @_;

    if ( defined $self->params->{$field} && $self->filters->{$filter} ) {
        $self->params->{$field} = $self->filters->{$filter}->( $self->params->{$field} )
            if $self->params->{$field};
    }
}

sub use_mixin {
    my ( $self, $field, $mixin_s ) = @_;

    $mixin_s = ref($mixin_s) eq "ARRAY" ? $mixin_s : [$mixin_s];

    if ( ref($mixin_s) eq "ARRAY" ) {
        foreach my $mixin ( @{$mixin_s} ) {
            if ( defined $self->{mixins}->{$mixin} ) {
                $self->fields->{$field} =
                  $self->_merge_field_with_mixin( $self->fields->{$field},
                    $self->{mixins}->{$mixin} );
            }
        }
    }

    return 1;
}

sub use_mixin_field {
    my ( $self, $field, $target ) = @_;

    $self->check_field( $field, $self->fields->{$field} );

    # name and label overwrite restricted
    my $name = $self->fields->{$target}->{name}
      if defined $self->fields->{$target}->{name};
    my $label = $self->fields->{$target}->{label}
      if defined $self->fields->{$target}->{label};

    $self->fields->{$target} =
        $self->_merge_field_with_field(
            $self->fields->{$target},
            $self->fields->{$field}
        );

    $self->fields->{$target}->{name}  = $name  if defined $name;
    $self->fields->{$target}->{label} = $label if defined $label;

    while ( my ( $key, $val ) = each( %{ $self->fields->{$field} } ) ) {
        if ( $key eq 'mixin' ) {
            $self->use_mixin( $target, $key );
        }
    }

    return 1;
}

sub use_validator {
    my ( $self, $field, $this ) = @_;

    # does field have a label, if not use field name
    my $name = $this->{label} ? $this->{label} : "parameter $field";
    my $value = $this->{value};

    # check if required
    if ( $this->{required} && ( !defined $value || $value eq '' ) ) {
        my $error =
          defined $this->{error} ? $this->{error} : "$name is required";
        $self->error( $this, $error );
        return 1;    # if required and fails, stop processing immediately
    }

    if ( $this->{required} || $value ) {

        # find and process all the validators
        foreach my $key (keys %{$this}) {
            if ($self->directives->{$key}) {
                if ($self->directives->{$key}->{validator}) {
                    if ("CODE" eq ref $self->directives->{$key}->{validator}) {
                        
                        # validate
                        my $result = $self->directives->{$key}
                        ->{validator}->($this->{$key}, $value, $this, $self);
                        
                    }
                }
            }
        }

    }

    return 1;
}

sub validate {
    my ( $self, @fields ) = @_;
    
    # first things first, reset the errors and value returning the validation
    # class to its pristine state
    $self->reset_fields();
    $self->reset_errors();
    
    # save unaltered state-of-parameters
    my %original_parameters = %{$self->params};

    # create alias map manually if requested
    if ( "HASH" eq ref $fields[0] ) {
        my $map = $fields[0];
        @fields = ();
        foreach my $param ( keys %{$map} ) {
            my $param_value = $self->params->{$param};
            delete $self->params->{$param};
            $self->params->{ $map->{$param} } = $param_value;
            push @fields, $map->{$param};
        }
    }
    
    # include fields stashed by the queue method
    if (@{$self->stashed}) {
        push @fields, @{$self->stashed};
    }
    
    # create map from aliases if applicable
    @fields = () unless scalar @fields;
    foreach my $field (keys %{$self->fields}) {
        my $f = $self->fields->{$field};
        if (defined $f->{alias}) {
            my $aliases = "ARRAY" eq ref $f->{alias} ?
                $f->{alias} : [$f->{alias}];
            
            foreach my $alias (@{$aliases}) {
                if (defined $self->params->{$alias}) {
                    my $param_value = $self->params->{$alias};
                    delete $self->params->{$alias};
                    $self->params->{ $field } = $param_value;
                    push @fields, $field;
                }
            }
        }
    }

    if ( scalar(keys(%{$self->params})) ) {
        if ( !@fields ) {

            # process all params
            foreach my $field ( keys %{ $self->params } ) {
                if ( !defined $self->fields->{$field} ) {
                    my $death_cert =
                        "Data validation field $field does not exist";
                    $self->_suicide_by_unknown_field($death_cert);
                    next;
                }
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};
                my @passed = ( $self, $this, $self->params );

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation
                if ( defined $self->fields->{$field}->{validation} ) {
                    unless ( $self->fields->{$field}->{validation}->(@passed) )
                    {
                        if ( defined $self->fields->{$field}->{error} ) {
                            $self->error( $self->fields->{$field},
                                $self->fields->{$field}->{error} );
                        }
                    }
                }
            }
        }
        else {
            foreach my $field (@fields) {
                if ( !defined $self->fields->{$field} ) {
                    my $death_cert
                        = "Data validation field $field does not exist";
                    $self->_suicide_by_unknown_field($death_cert);
                    next;
                }
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};
                my @passed = ( $self, $this, $self->params );

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation
                if ( defined $self->fields->{$field}->{validation} ) {
                    unless ( $self->fields->{$field}->{validation}->(@passed) )
                    {
                        if ( defined $self->fields->{$field}->{error} ) {
                            $self->error( $self->fields->{$field},
                                $self->fields->{$field}->{error} );
                        }
                    }
                }
            }
        }
    }
    else {
        if (@fields) {
            foreach my $field (@fields) {
                if ( !defined $self->fields->{$field} ) {
                    my $death_cert =
                        "Data validation field $field does not exist";
                    $self->_suicide_by_unknown_field($death_cert);
                    next;
                }
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};
                my @passed = ( $self, $this, $self->params );

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation
                if ( $self->fields->{$field}->{value}
                    && defined $self->fields->{$field}->{validation} )
                {
                    unless ( $self->fields->{$field}->{validation}->(@passed) )
                    {
                        if ( defined $self->fields->{$field}->{error} ) {
                            $self->error( $self->fields->{$field},
                                $self->fields->{$field}->{error} );
                        }
                    }
                }
            }
        }

        # if no parameters are found, instead of dying, warn and continue
        elsif ( !$self->params || ref( $self->params ) ne "HASH" ) {

            # warn
            #     "No valid parameters were found, " .
            #     "parameters are required for validation";
            foreach my $field ( keys %{ $self->fields } ) {
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation shouldn't fire without params and data
                # my @passed = ($self, $this, {});
                # $self->fields->{$field}->{validation}->(@passed);
            }
        }

        #default - probably unneccessary
        else {
            foreach my $field ( keys %{ $self->fields } ) {
                my $this = $self->fields->{$field};
                $this->{name}  = $field;
                $this->{value} = $self->params->{$field};

                # execute simple validation
                $self->use_validator( $field, $this );

                # custom validation shouldn't fire without params and data
                # my @passed = ($self, $this, {});
                # $self->fields->{$field}->{validation}->(@passed);
            }
        }
    }

    $self->params({%original_parameters});

    return @{ $self->{errors} } ? 0 : 1;    # returns true if no errors
}

sub _suicide_by_unknown_field {
    my $self  = shift;
    my $error = shift;
    if ($self->ignore_unknown) {
        if ($self->report_unknown) {
            push @{ $self->{errors} }, $error
                unless grep { $_ eq $error } @{ $self->{errors} };
        }
    }
    else {
        die $error ;
    }
}

sub _merge_field_with_mixin {
    my ($self, $field, $mixin) = @_;
    while (my($key,$value) = each(%{$mixin})) {
        
        # do not override existing keys but multi values append
        if (grep { $key eq $_ } keys %{$field}) {
            next unless $self->types->{field}->{$key}->{multi};
        }
        
        if (defined $self->types->{field}->{$key}) {
            # can the directive have multiple values, merge array
            if ($self->types->{field}->{$key}->{multi}) {
                # if field has existing array value, merge unique
                if ("ARRAY" eq ref $field->{key}) {
                    tie my @values, 'Array::Unique';
                    @values = @{$field->{$key}};
                    push @values, "ARRAY" eq ref $value ?
                        @{$value} : $value;
                    
                    $field->{$key} = [@values];
                }
                # simple copy
                else {
                    $field->{$key} = "ARRAY" eq ref $value ?
                        [@{$value}] : $value;
                }
            }
            # simple copy
            else {
                $field->{$key} = $value;
            }
        }
    }
    return $field;
}

sub _merge_field_with_field {
    my ($self, $field, $mixin_field) = @_;
    while (my($key,$value) = each(%{$mixin_field})) {
        
        # skip unless the directive is mixin compatible
        next unless $self->types->{mixin}->{$key}->{mixin};
        
        # do not override existing keys but multi values append
        if (grep { $key eq $_ } keys %{$field}) {
            next unless $self->types->{field}->{$key}->{multi};
        }
        
        if (defined $self->types->{field}->{$key}) {
            # can the directive have multiple values, merge array
            if ($self->types->{field}->{$key}->{multi}) {
                # if field has existing array value, merge unique
                if ("ARRAY" eq ref $field->{key}) {
                    tie my @values, 'Array::Unique';
                    @values = @{$field->{$key}};
                    push @values, "ARRAY" eq ref $value ?
                        @{$value} : $value;
                    
                    $field->{$key} = [@values];
                }
                # simple copy
                else {
                    $field->{$key} = "ARRAY" eq ref $value ?
                        [@{$value}] : $value;
                }
            }
            # simple copy
            else {
                $field->{$key} = $value;
            }
        }
    }
    return $field;
}

no Moose::Role;

1;