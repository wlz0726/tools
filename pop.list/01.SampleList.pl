# Sample List : /ifshk5/PC_PA_EU/PMO/F13FTSNCKF1344_SHEtbyR/zhuwenjuan/s1.data/new.combine.sheep.information
# remove list: /ifshk5/PC_PA_EU/PMO/F13FTSNCKF1344_SHEtbyR/zhuwenjuan/s1.data/jiangyu.removelist

my %remove=&hash_list("/ifshk5/PC_PA_EU/PMO/F13FTSNCKF1344_SHEtbyR/zhuwenjuan/s1.data/jiangyu.removelist");

open(I,"/ifshk5/PC_PA_EU/PMO/F13FTSNCKF1344_SHEtbyR/zhuwenjuan/s1.data/new.combine.sheep.information");
while(<I>){
    my @a=split(/\s+/);
    next if(exists $remove{$a[0]});
    print;
}
close I;



sub hash_list{
    my $input_file=shift;
    my %h;
    open(I,"$input_file");
    while(<I>){
	chomp;
	my @a=split(/\s+/);
	$h{$a[0]}++;
    }
    close I;
    return %h;
}
