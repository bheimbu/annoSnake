#!/usr/bin/env Rscript

library(dplyr)
library(tidyverse)

taxa<-read.csv(file.path(snakemake@params[["lca"]],"gtdb_vers202_lca.csv"),header=TRUE, sep=",")
taxa$X<-NULL
blast<-read.delim(snakemake@input[["input"]], header = F, sep = "\t", colClasses = "character")
options(scipen = 1)
blast2 <- subset(blast, V3 <= snakemake@params[["evalue"]])
taxa_blast<-merge(blast2,taxa,by.x="V2",by.y="taxID")
write.csv(taxa_blast,snakemake@output[["output"]])
