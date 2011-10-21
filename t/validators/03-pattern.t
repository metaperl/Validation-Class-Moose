use Test::More tests => 3;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {
        telephone => {
            pattern => '### ###-####'
        }
    },
    params => {
        telephone => '123 456-7890'
    }
);

ok  $r->validate(), 'telephone validates';
    $r->params->{telephone} = '1234567890';
    
ok  ! $r->validate(), 'telephone doesnt validate';
ok  'telephone does not match the pattern ### ###-####' eq $r->errors_to_string(),
    'displays proper error message';
    
#warn $r->errors_to_string();