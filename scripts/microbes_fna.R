#!/usr/bin/env Rscript

# Load the dplyr package for data manipulation
library(dplyr)

# Read the CSV file "BEC325.gtf" into a data frame called 'gtf'
gtf <- read.csv("BEC325.gtf", header=FALSE, sep="\t")

# Remove the ".gtf" extension from the values in the first column (V1) of 'gtf'
gtf$V1 <- gsub(".gtf", "", gtf$V1)

# Create a new column "names" by combining values from columns V1 and V2 with underscores
gtf$names <- paste(gtf$V1, gtf$V2, sep="_")

# Remove the prefix "gene_id " from values in the ninth column (V9) of 'gtf'
gtf$V9 <- gsub("gene_id ", "", gtf$V9)

# Create a new column "proteinnames" by combining values from columns V1 and V9 with underscores
gtf$proteinnames <- paste(gtf$V1, gtf$V9, sep="_")

# Read the CSV file "BEC325_blastx.txt.matches.lca.microbes.headers" into a data frame called 'microbescontigs'
microbescontigs <- read.csv("BEC325_blastx.txt.matches.lca.microbes.headers", header=FALSE)

# Filter rows in 'gtf' based on values in the "names" column and store the result in 'extracted'
extracted <- gtf %>% filter(names %in% microbescontigs$V1)

# Write the 'extracted' data frame to a CSV file named "gtdbmicrobial-230-13-prokka.map.gtf"
write.csv(extracted, file="gtdbmicrobial-230-13-prokka.map.gtf")


