#!/usr/bin/env perl6

subset SortBy of Str where any <key value keys values>;
sub MAIN (Str $file! where *.IO.f, SortBy :$sort-by = 'key', Bool :$desc=False) {
    my $bag    = $file.IO.lines.Bag;
    my @sorted = $sort-by ~~ /key/ ?? $bag.sort !! $bag.sort(*.value);
    @sorted   .= reverse if $desc;
    put @sorted.map(*.join("\t")).join("\n");
}
