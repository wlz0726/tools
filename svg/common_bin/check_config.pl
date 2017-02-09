use strict;
use warnings;
use File::Basename qw(dirname);
use Data::Dumper;

if (@ARGV != 1) {
	warn "usage: perl check_config.pl <config file>\n";
	exit;
}

my $conifg_file = shift;
my $bin = dirname ($conifg_file);
my %config_p;
my %prepare_bin;
my $error_status = 0;
open IN, $conifg_file || die "open error: $conifg_file\n";
while (<IN>) {
	chomp;
	next if (/^#/ || /^\s*$/);
	if (/(\S+)\s*:\s*"(\S+)"/) { 
		$prepare_bin{$1} = $2; 
		$prepare_bin{$1} =~ s/DIR_Bin/$bin/;
		next; 
	}

	if (/(\S+)\s*=\s*<\s*(.*)\s*>/) {
		my ($name, $path) = ($1, $2);
		$path =~ tr/"/\"/;
		$path =~ tr/$/\$/;
		while ($path =~ /(DIR_\w+)\//) {
			my $dir = $prepare_bin{$1};
			$path =~ s/$1/$dir/g;
		}
		$config_p{$name} = $path;
#tRNAscan = <export PERLLIB="$PERLLIB:DIR_Blc/tRNAscan-SE-1.3.1/bin"; DIR_Blc/tRNAscan-SE-1.23/bin/tRNAscan-SE>
	}
	elsif (/(\S+)\s*=\s*([^\/\s]+)(\/\S+)/) { $config_p{$1} = $prepare_bin{$2} . $3; }
	elsif (/(\S+)\s*=\s*(\/\S+)/) { $config_p{$1} = $2; }
}
close IN;

foreach (sort keys %config_p) {
	my @path = split (/\s+/, $config_p{$_});
	my $path = $path[-1];
	if (! -e $path) {
		warn "Non-exist: $_ $path\n";
		$error_status = 1;
	}
}
die "\nExit due to error of software configuration\n" if($error_status);
print "All path OK!\n";
