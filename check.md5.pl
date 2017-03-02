my @f=<*.md5sum>;
foreach my $f(@f){
    #`md5sum -c $f >>check.md5.pl.out`;
}
