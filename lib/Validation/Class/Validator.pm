use strict;
use warnings;

package Validation::Class::Validator;

use Moose::Role;

sub validate {
    print "printing from validate() provided by the Validator role\n";
}

no Moose::Role;

1;