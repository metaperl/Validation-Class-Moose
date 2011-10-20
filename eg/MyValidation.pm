package MyValidation;

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . '/../lib';
}

use Validation::Class;

mixin 'A' => {
    
};

mixin 'B' => {
    
};

field 'one' => {
    
};

field 'two' => {
    
};

field 'three' => {
    
};

1;