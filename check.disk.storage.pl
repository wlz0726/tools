#!/usr/bin/perl
use strict;
use warnings;

`df -h > ~/bin/check.disk.storage.pl.tmp`;

my $l1=`grep Filesystem ~/bin/check.disk.storage.pl.tmp`;

my $l2=`echo 01.cattle.CATwiwR.v2`;
my $l3=`grep ifshk5/BC_COM_P11 ~/bin/check.disk.storage.pl.tmp`;

my $l4=`echo 02.blind_mole_rat.RATxdeR`;
my $l5=`grep ifshk5/BC_COM_P11 ~/bin/check.disk.storage.pl.tmp`;

my $l6=`echo 03.sheep.SHEtbyR`;
my $l7=`grep ifshk5/BC_COM_P11 ~/bin/check.disk.storage.pl.tmp`;

my $l62=`echo 03.sheep.SHEtbyR.data`;
my $l72=`grep ifshk7/BC_COM_P10 ~/bin/check.disk.storage.pl.tmp`;

my $l8=`echo 04.zangyi.F13FTSNWKF2248_HUMmuzR.v2`;
my $l9=`grep ifshk7/BC_COM_P10 ~/bin/check.disk.storage.pl.tmp`;

my $l10=`echo 05.F16FTSNCWLJ1271.HUMzkbE.Aortic.aneurysm`;
my $l11=`grep ifshk7/BC_COM_P10 ~/bin/check.disk.storage.pl.tmp`;

print "$l1\n$l2$l3\n$l4$l5\n$l6$l7\n$l62$l72\n$l8$l9\n$l10$l11\n";
