use lib '.';
use MyValidation;

my $rules = MyValidation->new;
$rules->validate;

print "Done\n";