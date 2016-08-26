#!/usr/bin/env perl6

subset IO::Directory of Str where *.IO.d;

sub MAIN (IO::Directory :$src-dir!, :$dest-dir!, Int :$max=50000, Bool :v(:$verbose)) {
    my &verbose = $verbose ?? &note !! -> *@ {};
    die "dest-dir must be a directory" if $dest-dir.IO.e && $dest-dir !~~ IO::Directory;
    mkdir $dest-dir unless $dest-dir.IO.d;

    for dir($src-dir) -> $file {
        verbose "src-file: $file";
        my @dest-file-handles = lazy gather {
            # filenames are just strings. We can reverse them to make the last .
            # the first and use subst to replace only the first .
            my $numbered-file-name = $file.basename.flip.subst('.', '.1000-').flip;

            loop {
                verbose "dest-file: $numbered-file-name";
                take open($dest-dir.IO.child($numbered-file-name), :w);
                # The succ method of Perl 6 is quite clever.
                $numbered-file-name.=succ;
            }
        }

        my $out-fh = shift @dest-file-handles;
        my @buffer;
        my $i = 0;
        for $file.IO.lines -> $line {
            # start of a multi-line record is a ">"
            $i++ if $line ~~ /^'>'/;

            if $i == $max {
                $out-fh.put(@buffer.join("\n")) if @buffer;
                $out-fh.close;
                $out-fh = shift @dest-file-handles;
                $i      = 0;
                @buffer = ();
            }

            @buffer.push($line);
        }

        $out-fh.put(@buffer.join("\n")) if @buffer;
    }
}

=begin pod

=head1 NAME

fasta-split.pl6

=head1 DESCRIPTION

Splits a FASTA file into smaller files each of a "--max" number of 
records.  Useful for breaking large files up for BLAST, etc.

For usage, run with "-h/--help" or no arguments.

For sample FASTA input:

  $ wget ftp://ftp.imicrobe.us/projects/33/samples/713/HUMANGUT_SMPL_F1S.fa.gz

=head1 SEE ALSO

=item https://en.wikipedia.org/wiki/FASTA_format
=item https://github.com/MattOates/BioInfo
=item BioPerl6

=head1 AUTHOR

Ken Youens-Clark <kyclark@gmail.com>

=end pod
