if (@ARGV != 2) {
	warn "usage: perl fasta_1line.pl <input fasta> <output name>\n\n";
	exit;
}

my ($input, $output) = @ARGV;

open OUT, ">$output" || die;
open IN, $input || die;
$/ = ">";
<IN>;
while (<IN>) {
	chomp;
	my ($id, $seq) = split (/\n/, $_, 2);
	$seq =~ s/[\s\t\r\n]+//g;
	print OUT ">$id\n$seq\n";
}
$/ = "\n";
close IN;
close OUT;
