#!/usr/bin/perl
use strict;
use warnings;

my $f=shift;
die "$0 <file>
file example:
unique_id,birthday,gender
002442984c37af4ebefaf77118e41af6,1983-03-15,male
0024cf3d2cefebfd573438cb2dff0f66,1996-06-20,male
00342aea6250d2ad6f173cec55a4b71d,1998-10-30,female\n"unless $f;

# set missing --missing-phenotype
my $na="-9";


open(LOG,"> $f.log");
my $date=`date '+%Y %m'`;
chomp $date;
my @date=split(/\s/,$date);
my $year=$date[0];
my $month=$date[1];
#print "$year\t$month\n";die;

open(O,">$f.reprint");
open(I,"$f");
<I>;
while(<I>){
    chomp;
    my @a=split(/,/);
    my $uid=$a[0];
    my $birthday=$a[1];
    my $gender=$a[2];

    my $age;
    if($birthday =~ /NA/){
	$age=$na;
	print LOG "$uid\t$birthday\t$birthday\t$age\n";
    }elsif($birthday =~ /^(\d*)-(.*)-(.*)/){
	# $age=($year-$1)+($month-$2)/12;
	# $age=sprintf "%.2f",$age;
	$age=($year-$1);
	my $age_old=$age;
	if($age<5 || $age>90){
	    $age=$na;
	}
	print LOG "$uid\t$birthday\t$age_old\t$age\n";
    }else{
	die "$_\n";
    }
    
    my $gender2=$na;
    #if($gender =~ /NA/){
    if($gender =~ /NA/ || $gender =~ /unknow/ || $gender =~/other/){
	$gender2=$na;
    }elsif($gender=~/^female/){
	$gender2=2;
    }elsif($gender=~/^male/){
	$gender2=1;
    }else{
	die "$_\n";
    }
    #print "$gender\t$gender2\n";
    print O "$uid\t$age\t$gender2\n";
}
close I;
close O;
close LOG;
