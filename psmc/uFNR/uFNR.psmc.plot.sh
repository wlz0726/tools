perl plot_psmc.pl -M "FLV1=0.1,BRM1=0.1" test FLV1.psmc BRM1.psmc


Q:
Is it possible to plot PSMC by scaling Ne at 0.75 for chrX and alpha=2 for mutation rates directly using you plot function?

A:
You can do something like:

psmc_plot.pl -M"sample1@2*.75"

The "@" operator sets alpha and "*" to scale the population size.