#!/usr/bin/env perl6

class Person {
    has Str $.first_name is required;
    has Str $.last_name  is required;
}

my $geddy = Person.new(first_name => 'Geddy', last_name => 'Lee');
my $alex  = Person.new(frist_name => 'Alex',  last_name => 'Leifson');
my $neil  = Person.new(first_name => 'Neil',  last_neme => 'Peart');

for $geddy, $alex, $neil -> $person {
    printf "%s %s\n", $person.first_name, $person.last_name;
}
