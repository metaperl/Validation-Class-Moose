use Test::More tests => 1;

# load module
package MyVal; use Validation::Class;  package main;

my $v = MyVal->new(
    fields => {
        foobar => {
            filter => 'trim'
        }
    },
    params => {
        foobar => '       0011010101   '
    }
);

ok $v->params->{foobar} =~ /^0011010101$/, 'trim filter working as expected';