#!/usr/bin/env perl6

class Fastq-Entry {
    has Str $.header;
    has Str $.seq;
    has Str $.qual;
    has Str $.name = "";
    has Int $.num  = 0;
    has Int $.dir  = 0;

    submethod BUILD (Str :$!header, Str :$!seq, Str :$!qual) { 
        # Extract name, read number and direction from header, e.g:
        #   header: @SRR1647045.4.1 4 length=69
        #       name = SRR1647045
        #       num = 4   (read number)
        #       dir = 1   (direction)
        if my $match = $!header ~~ /^\s* '@' (\w+) '.' (\d+) '.' (<[12]>) \s/ {
            ($!name, $!num, $!dir) = (~$match[0], +$match[1], +$match[2]);
        }
    }

    method Str {
        return join "\n", $.header, $.seq, '+', $.qual;
    }
}

class Fastq {
    has Str $.filename;
    has Str $.outfilename;
    has Str $.out-dir;
    has Int $.dir;
    has IO::Handle $!in_fh;
    has IO::Handle $!out_fh;
    has IO::Handle $.singleton_fh;

    submethod BUILD (Str :$!filename, Str :$!out-dir, Int :$!dir ){
        # e.g., SRR1647045_1.trim.fastq => SRR1647045_R1.fastq
        (my $basename = $!filename) ~~ s/'_'<[12]> .*//;
        my $basepath = $*SPEC.catfile($!out-dir, $basename );

        $!outfilename = $basepath ~ '_R' ~ $!dir ~ '.fastq';
        my $singleton_fn = $basepath ~ '_singletons.fastq';

        mkdir $!out-dir unless $!out-dir.IO.d;

        $!in_fh = open $!filename;
        $!out_fh = open $!outfilename, :w;
        $!singleton_fh = open $singleton_fn, :w if $!dir == 1;
    }


    method next {
        return Nil if $!in_fh.eof;

        my ($header, $seq="", $="", $qual="") = $!in_fh.lines;

        return Fastq-Entry.new(
            header => ~$header,
            seq    => ~$seq,
            qual   => ~$qual,
        );
    }

    method write( Fastq-Entry $fastq ) {
        $!out_fh.put( $fastq );
    }

    # This is clumsy, but we don't want two filehandles to the singleton file
    method write-singleton( Fastq-Entry $fastq ) {
        die "singleton can only be called on direction 1" if $!dir != 1;
        $.singleton_fh.put( $fastq );
    }
}

# --------------------------------------------------
subset File of Str where *.IO.f;
sub MAIN (
    File :$r1!,
    File :$r2!,
    Str :$out-dir=$*SPEC.catdir($*CWD, 'out')
) {
    my $fastq1 = Fastq.new( filename => $r1, out-dir => $out-dir, dir => 1 );
    my $fastq2 = Fastq.new( filename => $r2, out-dir => $out-dir, dir => 2 );

    my ($read1, $read2) = ($fastq1.next, $fastq2.next);
    loop {
        last unless $read1 || $read2;

        given ($read1, $read2) {
            when (Fastq-Entry, Nil) { $fastq1.write-singleton($read1) }

            when (Nil, Fastq-Entry) { $fastq1.write-singleton($read2) }

            when (Fastq-Entry, Fastq-Entry) {

                if $read1.num == $read2.num {
                    $fastq1.write( $read1 );
                    $fastq2.write( $read2 );
                }
                else {
                    if $read1.num < $read2.num {
                        $fastq1.write-singleton( $read1 );
                        $read1 = $fastq1.next;
                    } else {
                        $fastq1.write-singleton( $read2 );
                        $read2 = $fastq2.next;
                    }
                    redo;
                }
            }

        }

        ($read1, $read2) = ($fastq1.next, $fastq2.next);
    }

    put "Done.";
}
