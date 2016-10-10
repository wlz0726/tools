
# Usage: Rscript printGLF.R -i infile.glf.gz -n 1000 -d 20 -o outfile.txt

library(optparse)

option_list <- list(make_option(c('-i','--in_file'), action='store', type='character', default=NULL, help='Input file'),
		make_option(c('-o','--out_file'), action='store', type='character', default=NULL, help='Output file'),
		make_option(c('-n','--nsites'), action='store', type='numeric', default=NULL, help='Number of sites'),
		make_option(c('-d','--nind'), action='store', type='numeric', default=NULL, help='Number of individual')
                    )
opt <- parse_args(OptionParser(option_list = option_list))

ncat=10;

ff <- gzfile(opt$in_file,"rb");

m<-matrix(readBin(ff,"double",ncat*opt$nsites*opt$nind),ncol=ncat,byrow=TRUE);

colnames(m)=c("AA", "AC", "AG", "AT", "CC", "CG", "CT", "GG", "GT", "TT");

m=cbind(indiv=rep(1:opt$nind, opt$nsites), site=rep(1:opt$nsites, each=opt$nind), m);

close(ff)

write.table(m, file=opt$out_file, col.names=T, sep="\t", row.names=F, quote=F);


