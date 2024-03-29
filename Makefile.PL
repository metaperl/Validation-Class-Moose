
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Centralized Input Validation for Any Application\r",
  "AUTHOR" => "Al Newkirk <awncorp\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Validation-Class",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Validation::Class",
  "PREREQ_PM" => {
    "Array::Unique" => 0,
    "Carp" => 0,
    "Hash::Flatten" => 0,
    "Module::Find" => 0,
    "Moose" => 0,
    "MooseX::Traits" => 0,
    "Scalar::Util" => 0
  },
  "VERSION" => "2.4.3",
  "test" => {
    "TESTS" => "t/*.t t/filters/*.t t/validators/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



