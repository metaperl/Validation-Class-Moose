use Test::More tests => 3;

package MyVal;
use Validation::Class;

package main;

my $passer = sub { 1 };

my $mixins = {
    'mix1',
    {
	required   => 1
    }
};

my $fields = {

    'test1',
    {
	label      => 'user login',
	error      => 'login invalid',
	validation => $passer,
	mixin      => 'mix1',
	alias      => [ 'name', 'user' ],
    },

    'test2',
    {
	label       => 'user password',
	mixin_field => 'abcdef'
    },

    'test3',
    {
	label      => 'user name',
	error      => 'invalid name',
	validation => sub { 888 },
	mixin      => 'mix1'
    },

    'test4',
    {
	mixin       => 'mix1',
	mixin_field => 'test1',
	mixin_field => 'test3'
    },

};

my $v = MyVal->new(
    mixins => $mixins,
    fields => $fields,
    params => { user => 'p3rlc0dr' }
);

# class init
ok $v, 'validation-class initialized';

# mixins and fields registered without keywords
ok scalar( keys %{ $v->fields } ), 'fields registration ok';
ok scalar( keys %{ $v->mixins } ), 'mixins registration ok';

my $foo;
