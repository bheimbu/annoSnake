#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 microbes_headers gtf_file output_bed_file"
    exit 1
fi

# Assign command-line arguments to variables
microbes_headers="$1"
gtf_file="$2"
output_bed_file="$3"

# Extract the sample name from the gtf_file (e.g., BED325.gtf => BED325)
sample=$(basename "$gtf_file" .gtf)

# Create the intermediate filtered GTF file name
filtered_gtf_file="$sample"_filtered.gtf

# Step 1: Filter GTF Entries Based on Contig Names
grep -w -f "$microbes_headers" "$gtf_file" > "$filtered_gtf_file"

# Step 2: Extract and Filter Unique Contigs
awk 'BEGIN {OFS="\t"} !seen[$1]++ {split($9, a, "gene_id "); gsub(/;/, "", a[2]); print $1, $4 - 1, $5, a[2], $7}' "$filtered_gtf_file" > "$output_bed_file"

# Cleanup intermediate files (optional)
rm "$filtered_gtf_file"
