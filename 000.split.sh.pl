#!/usr/bin/perl -w
# split sh file perl N line
open (IN, "$ARGV[0]" ) || do {
    print "\nCan not open file\nUsage:splitfile.pl Filename SplitLinesPerFile\n";
    exit 0; };
@char = <IN>;
close IN;

!$ARGV[1] && do {	
    print "\nno SplitLinesPerFile\nUsage:splitfile.pl Filename SplitLinesPerFile\n";
    exit 0; };

@char<=$ARGV[1] && do {
    print "\nSplitLinesPerFile is too big.\n";
    exit 0; };
($j = @char/$ARGV[1]) =~ s/\..*//;

@char%$ARGV[1] && $j++;

for ($i=1, $f=A; $i<=$j; $i++, $f++) {
    open ($f, "> $ARGV[0].s.$i" ) || do {
        print "\nsplit file $ARGV[0].split.$i failed!\n";
        exit 0; };
    &RW($f);
    close ($f);
}

sub RW {
    my ($a) = @_;
    @$a = splice (@char, 0, $ARGV[1]);
    select $a;
    print @$a;
}
