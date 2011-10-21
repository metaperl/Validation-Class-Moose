use Test::More tests => 1;

# load module
package MyVal; use Validation::Class;  package main;

my $v = MyVal->new(
    fields => {
        foobar => {
            filter => 'uppercase'
        }
    },
    params => {
        foobar => '123abc456def'
    }
);

ok $v->params->{foobar} =~ /^123ABC456DEF$/, 'uppercase filter working as expected';
