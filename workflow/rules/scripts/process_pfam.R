# process_pfam.R

# Load required libraries
library(data.table)

# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if the correct number of arguments is provided
if (length(args) != 2) {
  stop("Usage: Rscript process_pfam.R input_file output_file")
}

# Read input CSV
input_file <- args[1]
pfam <- read.csv(input_file, header = FALSE)

# Convert to data.table
setDT(pfam)

# Group and concatenate annotations
pfam2 <- as.data.table(pfam)[, toString(V2), by = list(V1, V3)]

# Write the result to the output file
output_file <- args[2]
write.csv(pfam2, file = output_file)
