use Test::More tests => 3;

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/modules";
}

package MyVal;

use Validation::Class;

__PACKAGE__->load_classes;
__PACKAGE__->load_plugins('+MyVal::Plugin::Glade');

package main;

my $v = MyVal->new( params => { foo => 1 } );

ok $v, 'initialization successful';

ok $v->smell &&
   $v->squirt, 'glade plugin applied to base';

my $p = $v->class('person');

ok $p->smell &&
   $p->squirt, 'glade plugin applied to person';