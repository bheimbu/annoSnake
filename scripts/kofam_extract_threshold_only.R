#!/usr/bin/env Rscript

args <- commandArgs(TRUE)
kofam <- args[1]
output_file1 <- args[2]
output_file2 <- args[3]

library(tidyr)
library(stringr)
library(data.table)
library(dplyr)

kofam<-read.csv(file=kofam,sep="\t",header=TRUE)

kolist<-read.csv("../../../databases/ko_list",header=TRUE,sep="\t")
kolist<-kolist%>%select(knum,threshold)
colnames(kolist)<-c("knum","kthreshold")

#join the two files-
kofam_klist<-merge(kofam,kolist,by.x=c("KO"),by.y=c("knum"),all.x=TRUE)
kofam_klist$X.<-NULL
kofam_klist<-unique(kofam_klist)

#filter the KOs by their thresholds-
kofam_klist<-kofam_klist%>%mutate(keepkos=ifelse(as.numeric(thrshld)>=as.numeric(kthreshold),"aboveandequal","less"))
kofam_klist_selected<-kofam_klist%>%filter(keepkos=="aboveandequal")

kofam_klist_selected$E.value<-as.numeric(as.character(kofam_klist_selected$E.value))

write.csv(kofam_klist_selected,file=output_file1) #...(A)
#-------------------------------------------------------------------------------------------
#get all koids per geneid in a single columns-
setDT(kofam_klist_selected)
kofamall<-as.data.table(kofam_klist_selected)[, toString(KO), by = (gene.name)]

#and get the kegg with the smallest evalue-
setDT(kofam_klist_selected)
kofamevalue<-setDT(kofam_klist_selected)[ , .SD[which.min(E.value)], by = gene.name]

#make sure that genes of interest are present in the dataset ifnot then make sure that other KEGGids with min. e-value are showed-
kofamall_evalue<-merge(kofamall,kofamevalue,by="gene.name") #join  the two dataframes

#get all the genes from the metabolic pathways-
#<on multiple keggids>
genes<-c("K01938","K01491","K13990","K00297","K00122","K00198","K14138","K00194","K00197","K15023","K00625","K00925","K00394","K00395","K00958","K11180","K11181","K02586","K02591","K02588","K02587","K02592","K02585","K00370","K00371","K00374","K02567","K02568","K00362","K00363","K03385","K15876","K01428","K01429","K01430","K00265","K00266","K01915","K03320","K11959","K11960","K11961","K11962","K11963","K00926","K00611","K01940","K01755","K00399","K00401","K00402")

#(B) str_extract based on genes of interest-
kofamall_evalue <- kofamall_evalue %>% mutate(kofamselected=(str_extract(V1, str_c(genes, collapse = "|"))))
#keep the extracted genes OR KEGGids with min evalue-
kofamall_evalue<-kofamall_evalue%>%mutate(finalkofam=ifelse(is.na(kofamselected),as.character(KO),kofamselected))

#select the columns of interest-
kofamall_evalue2<-kofamall_evalue%>%select(gene.name,finalkofam)
kofamall_evalue2$samples<-gsub("_.*$","",kofamall_evalue$gene.name)
kofamall_evalue2$protein1<-unlist(lapply(strsplit(as.character(kofamall_evalue2$gene.name),split="_"),"[",2))
kofamall_evalue2$protein2<-unlist(lapply(strsplit(as.character(kofamall_evalue2$gene.name),split="_"),"[",3))
kofamall_evalue2$proteins<-paste(kofamall_evalue2$protein1,kofamall_evalue2$protein2,sep="_")
colnames(kofamall_evalue2)[which(names(kofamall_evalue2) == "finalkofam")] <- "annotation"
colnames(kofamall_evalue2)[which(names(kofamall_evalue2) == "gene.name")] <- "fullproteinnames"

kofamall_evalue2<-kofamall_evalue2%>%select(samples,proteins,annotation,fullproteinnames)
write.csv(kofamall_evalue2,file=output_file2)