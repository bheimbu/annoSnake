#!/usr/bin/env Rscript
library(dplyr)
library(tidyverse)

# Read LCA file
taxa <- read.csv(file.path(snakemake@params[["lca"]]), header = TRUE, sep = ",")

# Remove X column if it exists
if ("X" %in% colnames(taxa)) {
  taxa$X <- NULL
}

# Read BLAST results
blast <- read.delim(snakemake@input[["input"]], header = FALSE, sep = "\t", 
                    colClasses = "character")

options(scipen = 1)

# Filter by e-value
blast2 <- subset(blast, V3 <= snakemake@params[["evalue"]])

# Merge BLAST results with taxonomy
# Note: V2 should be the taxID column from DIAMOND output
taxa_blast <- merge(blast2, taxa, by.x = "V2", by.y = "taxID")

# Write output
write.csv(taxa_blast, snakemake@output[["output"]], row.names = FALSE)