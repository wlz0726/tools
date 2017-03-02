use strict;
use warnings;

my $modelgenerator="/home/share/user/user102/tools/ModelGenerator/modelgenerator.jar";
my @in=<2.*fas>;
for my $in (@in){
		$in=~/2\.([^\/]+)\.fas$/;
		print "java -jar $modelgenerator $in 8 ; mv modelgenerator1.out modelgenerator.$1.out\n";
	}