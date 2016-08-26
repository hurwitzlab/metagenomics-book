#!/usr/bin/env perl6

subset IO::Directory of Str where *.IO.d;

sub MAIN (IO::Directory :$in-dir!, IO::Directory :$out-dir!, Int :$max=50000) {
    mkdir $out-dir unless $out-dir.IO.d;

    for dir($in-dir) -> $file {
        my &next-fh = sub {
            state $file-num = 1;
            my $ext      = '.' ~ $file.extension;
            my $basename = $file.basename.subst(/$ext $/, '');
            open $*SPEC.catfile(
                $out-dir, 
                sprintf('%s-%03d%s', $basename, $file-num++, $ext)
            ), :w;
        };

        my $out-fh = next-fh();
        my @buffer;
        my $i = 0;
        for $file.IO.lines -> $line {
            # start of a multi-line record is a ">"
            $i++ if $line ~~ /^'>'/;

            if $i == $max {
                $out-fh.put(@buffer.join("\n")) if @buffer;
                $out-fh.close;
                $out-fh = next-fh();
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
