#!/usr/bin/perl -w
use strict;
use File::Path;
use Getopt::Long;
use File::Basename;
use FindBin '$Bin';

#Author: linruichai@genomics.cn
#Date: 2016-3-28

#read option
my ($outdir,$expMatrix,$weight);
GetOptions(
	"expMatrix=s"=>\$expMatrix,
	"weight:f"=>\$weight,
	"outdir:s"=>\$outdir,
);

die "
Description:
    Get gene co-expression network with WGCNA method.
Usage:
	*-expMatrix	<file>	matrix file of gene expression value, gene in row and sample in column
	 -weight	<int>	threshold of weight value to present correlation between genes, the greater weight value is, the more co-expressed genes are, deault:0.8
	 -outdir	<file>	default: current dir
e.g.
    perl $0 -expMatrix expMatrix.xls -weight 0.8 -outdir ./
" unless ($expMatrix);

$outdir ||= "./";
$weight ||= 0.8;

$expMatrix = File::Spec->rel2abs($expMatrix);
mkpath $outdir unless (-f $outdir);
$outdir = File::Spec->rel2abs($outdir);

my $head = `head -1 $expMatrix`;
my $column = "";
my $altNodeNames = "";
if($head =~ m/Symbol/){
	$column = "-c(1:2)";
	$altNodeNames = "femData\\\$Symbol";
}else{
	$column = "-c(1:1)";
	$altNodeNames = "NA";
}

my $cytoscape_R = <<RCODE;
library(WGCNA)
library(flashClust)
library(iterators)
options(stringsAsFactors = FALSE)
enableWGCNAThreads()

femData = read.table('$expMatrix',header=TRUE)
datExpr = as.data.frame(t(femData[, $column]))

# gene names
names(datExpr) = femData\\\$GeneID

#sample names
rownames(datExpr) = names(femData)[$column]

gsg = goodSamplesGenes(datExpr, verbose = 3)
gsg\\\$allOK

gene.names=names(datExpr)

# Choosing a soft-threshold to fit a scale-free topology to the network
powers = c(c(1:10), seq(from = 12, to=30, by=2))
sft=pickSoftThreshold(datExpr,dataIsExpr = TRUE,powerVector = powers,corFnc = cor,corOptions = list(use = 'p'),networkType = 'unsigned')
Rsquare<-(-sign(sft\\\$fitIndices[,3])*sft\\\$fitIndices[,2])
softPower <- sft\\\$fitIndices[which(Rsquare==max(Rsquare)),1]

TOM=TOMsimilarityFromExpr(datExpr,networkType = 'unsigned', TOMType = 'unsigned', power = softPower)

# Export the network into edge and node list files Cytoscape can read
probes = names(datExpr)
altNodeNames = $altNodeNames
cyt = exportNetworkToCytoscape(TOM, edgeFile = paste('$outdir/CytoscapeInput-edges', '.txt', sep=''), weighted = TRUE, threshold = $weight, nodeNames = probes, altNodeNames = altNodeNames);
RCODE

`echo "$cytoscape_R" >$outdir/WGCNA_cytoscape.R`;
`export LD_LIBRARY_PATH=/opt/blc/gcc-4.5.0/lib/:/opt/blc/gcc-4.5.0/lib64/:\$LD_LIBRARY_PATH && export PATH=/opt/blc/gcc-4.5.0/bin:\$PATH && $Bin/R --max-vsize=20G CMD BATCH $outdir/WGCNA_cytoscape.R`;
`perl $Bin/extractGene.pl $outdir/CytoscapeInput-edges.txt $expMatrix >$outdir/geneExpMatrix.InCytoscape.txt`;


# detect modules and draw module heatmap based on filtering genes in CytoscapeInput-edges.txt
my $heatmap_R = <<RCODE;
library(WGCNA)
library(flashClust)
library(iterators)
options(stringsAsFactors = FALSE)
enableWGCNAThreads()

femData = read.table('$outdir/geneExpMatrix.InCytoscape.txt',header=TRUE)
datExpr = as.data.frame(t(femData[, $column]))

# gene names
names(datExpr) = femData\\\$GeneID

#sample names
rownames(datExpr) = names(femData)[$column]

gsg = goodSamplesGenes(datExpr, verbose = 3)
gsg\\\$allOK

gene.names=names(datExpr)

# Choosing a soft-threshold to fit a scale-free topology to the network
powers = c(c(1:10), seq(from = 12, to=30, by=2))
sft=pickSoftThreshold(datExpr,dataIsExpr = TRUE,powerVector = powers,corFnc = cor,corOptions = list(use = 'p'),networkType = 'unsigned')
Rsquare<-(-sign(sft\\\$fitIndices[,3])*sft\\\$fitIndices[,2])
softPower <- sft\\\$fitIndices[which(Rsquare==max(Rsquare)),1]

TOM=TOMsimilarityFromExpr(datExpr,networkType = 'unsigned', TOMType = 'unsigned', power = softPower)

colnames(TOM) =rownames(TOM) =gene.names
dissTOM=1-TOM

# Module detection
geneTree = flashClust(as.dist(dissTOM),method='average')

# Set the minimum module size
minModuleSize = 20

# Module identification using dynamic tree cut
dynamicMods = cutreeDynamic(dendro = geneTree, distM = dissTOM, method='hybrid', deepSplit = 2, pamRespectsDendro = FALSE, minClusterSize = minModuleSize)

#the following command gives the module labels and the size of each module. Lable 0 is reserved for unasunsigned genes
table(dynamicMods)

#Plot the module assignment under the dendrogram; note: The grey color is reserved for unasunsigned genes
dynamicColors = labels2colors(dynamicMods)
table(dynamicColors)

#discard the unasunsigned genes, and focus on the rest
restGenes= (dynamicColors != 'grey')
diss1=1-TOMsimilarityFromExpr(datExpr[,restGenes], power = softPower)
hier1=flashClust(as.dist(diss1), method='average')

#set the diagonal of the dissimilarity to NA
diag(diss1) = NA

#Visualize the Tom plot. Raise the dissimilarity matrix to the power of 4 to bring out the module structure
pdf('$outdir/Modules_heatmap.pdf')
TOMplot(diss1, hier1, as.character(dynamicColors[restGenes]))
dev.off()

# Extract modules
module_colors= setdiff(unique(dynamicColors), 'grey')

for (color in module_colors){
    module=gene.names[which(dynamicColors==color)]
    write.table(module, paste('$outdir/Modules_gene_',color, '.txt',sep=''), sep="\t", row.names=FALSE, col.names=FALSE,quote=FALSE)
}

RCODE

`echo "$heatmap_R" >$outdir/WGCNA_heatmap.R`;
`export LD_LIBRARY_PATH=/opt/blc/gcc-4.5.0/lib/:/opt/blc/gcc-4.5.0/lib64/:\$LD_LIBRARY_PATH && export PATH=/opt/blc/gcc-4.5.0/bin:\$PATH && $Bin/R --max-vsize=20G CMD BATCH $outdir/WGCNA_heatmap.R`;
`$Bin/convert -density 150 $outdir/Modules_heatmap.pdf $outdir/Modules_heatmap.png`;

#`rm $outdir/WGCNA_heatmap.R $outdir/WGCNA_heatmap.R $outdir/geneExpMatrix.InCytoscape.txt`;
