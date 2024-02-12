#!/usr/bin/env Rscript

library(data.table)

args <- commandArgs(TRUE)
pfam <- args[1]
output <- args[2]

pfam<-read.csv(pfam,header=FALSE)
setDT(pfam)
pfam2<-as.data.table(pfam)[, toString(V2), by = list(V1,V3)]		###convert pfam annotation column toString using proteinID and sampleID columns as groups.
write.csv(pfam2,file=output)