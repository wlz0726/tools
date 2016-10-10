getMultiFST<-function(filein, fileout, from_known=FALSE, len_win=0) {

	# len_win: length of windows

	i1=1; if (from_known) i1=8;

	val=c()
    	rt=read.table(filein,head=F)
    	ltot=nrow(rt);
    	if (len_win>0) {
     		start=seq(1, ltot, len_win);
     		end=c(seq(len_win+1, ltot, len_win), ltot); end=end[1:length(start)]-1; end[length(end)]=ltot;
     		for (f in 1:length(start)) val=c(val, rep( (sum(rt[start[f]:end[f],i1])/sum(rt[start[f]:end[f],(i1+1)])) , (end[f]-start[f]+1) ) )
		if (length(val)==ltot) {
                        write.table(cbind(rep(0,nrow(rt)),rep(0,nrow(rt)),rep(0,nrow(rt)),val,rep(0,nrow(rt))), sep="\t", quote=F, row.names=F, col.names=F, file=fileout)
                } else {
                        cat("\nProgram terminates here. The number of values is different than the original file size.\n");
                        return(0);
                }
	} else {
      		val=sum(rt[,1])/sum(rt[,2])
		write.table(cbind(rep(0,nrow(rt)),rep(0,nrow(rt)),rep(0,nrow(rt)),rep(val,nrow(rt)),rep(0,nrow(rt))), sep="\t", quote=F, row.names=F, col.names=F, file=fileout)
    	}
  	
}
