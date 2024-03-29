use Test::More tests => 15;

package MyVal;

use Validation::Class;

mixin ID => {
    required   => 1,
    min_length => 1,
    max_length => 11
};

mixin TEXT => {
    required   => 1,
    min_length => 1,
    max_length => 255
};

field id => {
    mixin => 'ID',
    label => 'Object ID',
    error => 'Object ID error'
};

field name => {
    mixin => 'TEXT',
    label => 'Object Name',
    error => 'Object Name error'
};

field email => {
    mixin => 'TEXT',
    label => 'Object Email',
    error => 'Object Email error',
    max_length => 500
};

field email_confirm => {
    mixin_field => 'email',
    label => 'Object Email Confirm',
    error => 'Object Email confirmation error',
    min_length => 5
};

package main;
my $p = { name => '', email => 'awncorp@cpan.org' };
my $v = MyVal->new( params => $p );

ok $v, 'initialization successful';
ok $v->queue(qw/name email/);
ok ! $v->validate, 'validation failed';
ok $v->error_count == 1, 'expected number of errors';
ok ! $v->validate('id'), 'validation failed';
ok $v->error_count == 2, 'expected number of errors';
ok $v->param(qw/name AWNCORP/) eq 'AWNCORP', 'set parameter ok';
ok $v->param(qw/id 100/) == 100, 'set parameter ok';
ok $v->validate, 'validation succesful';
ok ! $v->error_count, 'no errors';
ok $v->validate('id'), 'validation succesful';
ok ! $v->error_count, 'no errors';
ok $v->reset, 'reset ok';
ok ! $v->validate(keys %{$v->fields}), 'validate all (not stashed) failed';
ok $v->error_count == 1, 'error - email_confirm not set';


