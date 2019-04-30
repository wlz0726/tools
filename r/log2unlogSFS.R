
# Usage: Rscript log2unlogSFS.R -i in.sfs.ml -o out.sfs.ml

library(optparse)

option_list <- list(make_option(c('-i','--in_file'), action='store', type='character', default=NULL, help='Input file'),
                    make_option(c('-o','--out_file'), action='store', type='character', default=NULL, help='Output file')
                    )
opt <- parse_args(OptionParser(option_list = option_list))

# Read input file
values <- exp(as.numeric(scan(opt$in_file, what="char")));
# Write
cat(values, sep=" ", file=opt$out_file);


