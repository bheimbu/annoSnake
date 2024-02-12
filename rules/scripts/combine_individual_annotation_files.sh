#!/usr/bin/bash

### combine all individual annotation files from Snakemake workflow

cat cazy/*/*.top >> cazy/final_cazy_evalue30.txt

cat kegg/*/*.kofam_klist_selected >> kegg/final_kofam_multiple_ids.txt
		
cat pfam/*/*.pfam.evalue30 >> pfam/pfam_evalue30.txt
awk '{{print $1","$6","$7}}' pfam/pfam_evalue30.txt > pfam/pfam_evalue30.columns
Rscript scripts/final_pfam_annotated_file_for_all_samples.R pfam/pfam_evalue30.columns pfam/final_pfam_evalue30.txt
