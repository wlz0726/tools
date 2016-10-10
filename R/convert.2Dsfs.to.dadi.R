
## This script has been provided by Jacob Crawford

args <- commandArgs(TRUE);
if(length(args)==0){
	print('Usage: Convert matrix style 2D SFS to dadi format array style with sample sizes and polarization in header');
	cat('Supply two arguments - \n 1) 2D SFS file name (and path if not in working directory) \n 2) \'folded\' or \'unfolded\' \n');
	return();
}
if(length(args)==2){
	file=as.character(args[1]);
	pol=as.character(args[2]);
}else if(length(args)==1){
	cat('ERROR: must supply two arguments - \n 1) 2D SFS file name (and path if not in working directory) \n 2) \'folded\' or \'unfolded\' \n');
	return();
}

if(is.element(pol,c('folded','unfolded'))==FALSE){
	print('ERROR: Second argument must be either \'folded\' or \'unfolded\' to indicate polarization of SFS \n');
	return();
} 

# Read in 2D sfs 
sfs=read.table(file);

# Get sample sizes and make header
n1=nrow(sfs);
n2=ncol(sfs);
ns=paste(n1,n2,collapse=' ');
ns=paste(ns,pol,collapse=' ');

# Convert 2D sfs to dadi array format
dadi=NULL;
for(i in 1:n1){
	dadi=c(dadi,as.numeric(sfs[i,]))
}

# Write out dadi format to file with same name as 2D sfs file with .fs appeded
write.table(ns,file=paste(file,'.fs',sep=''),col.names=FALSE,row.names=FALSE,quote=FALSE);	
write.table(paste(dadi,collapse=' '),file=paste(file,'.fs',sep=''),col.names=FALSE,row.names=FALSE,quote=FALSE,append=TRUE);

## 

