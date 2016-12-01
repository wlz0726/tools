my $path=shift;
die "$0 /path/to/absolute/dir/path\n"unless $path;
my @in=`find $path -regextype "posix-egrep" -regex ".*\.(pl|sh|py|r|pdf|xls)\$"`;
#print "@in";
for my $in (@in){
    chomp $in;
    my $in2=$in;
    $in2=~s/\/ifshk5\/PC_HUMAN_EU\/USER\/jinwei\/YAO_work\///; # path
    my $dir=$in2;
    $dir=~s/\/[^\/]+$//;
    `mkdir -p $dir` unless ( -e "$dir");
    `cp $in $in2`;
}
