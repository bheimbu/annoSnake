#!/usr/bin/env Rscript

library(dplyr)

taxa<-read.table(file.path(snakemake@params[["lca"]],"gtdb_vers202_lca.csv"),header=TRUE, sep=",")
taxa$X<-NULL

blast<-read.csv(snakemake@input[["input"]],header=FALSE,sep="\t")
blast2<-blast%>%filter(V3<=snakemake@params[["evalue"]])

taxa_blast<-merge(blast2,taxa,by.x="V2",by.y="taxID")
write.csv(taxa_blast,snakemake@output[["output"]])