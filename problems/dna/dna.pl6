#!/usr/bin/env perl6

=begin pod

=head1 NAME

dna.pl6

=head1 SYNOPSIS

  ./dna.pl6 AACATAAATCACT
  ./dna.pl6 sequence.txt

=head1 DESCRIPTION

This is a solution for http://rosalind.info/problems/dna/.  It will 
print the number of times the bases A, C, G, and T (in that order) for 
a string of sequence provided either on the command line or in a file.

=head1 AUTHOR

Ken Youens-Clark <kyclark@email.arizona.edu>

=end pod

sub MAIN (Str $input!) {
    die "cannot work with directories" of $input.IO.d;
    my $dna = $input.IO.f ?? $input.IO.slurp !! $input;
    my $bag = $dna.lc.comb.Bag;
    put join ' ', $bag<a c g t>
}
