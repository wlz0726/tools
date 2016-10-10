my $f=shift;

my %h;
open(IN, "/home/share/user/user104/projects/yak/ref/yak0803_v2.sca.break.fa.filter2K.fa.Length.stat.list");
while(<IN>){
    chomp;
    my @a=split (/\s+/);
    $h{$a[0]}=$a[1];
}
close IN;

open(OUT, "> $f.mean.out");

my $num=0;
my $pi=0;
open(IN, "$f");
my @data;
while(<IN>){
    chomp;
    my @a=split (/\s+/);
    next if($a[2] > $h{$a[0]});
    $pi += $a[3];
    push(@data,$a[3]);
    $num++;
}
close IN;
my $a=@data;
print "$a\n";
my $meanPi=$pi/$num;
my $av=&average(@data);
my $stsd=&stdev(@data);
print OUT "$f\t$meanPi
average : $av
stdev : $stsd
\n";

close OUT;


sub average{
    my(@data) = @_;
    if (@data == 0){
        #die("Empty array\n");
    }
    my $total = 0;
    foreach (@data) {
        $total += $_;
    }
    my $average = $total / @data;
    return $average;
}
sub stdev{
    my(@data) = @_;
    if(@data == 1){
        return 0;
    }
    my $average = &average(@data);
    my $sqtotal = 0;
    foreach(@data) {
        $sqtotal += ($average-$_) ** 2;
    }
    my $std = ($sqtotal / (@data-1)) ** 0.5;
    return $std;
}
