#!/usr/bin/env python
"""
Create LCA (Lowest Common Ancestor) lookup table for GTDB r226.
Uses GTDB metadata files for taxonomy strings and names.dmp from
taxonkit create-taxdump to get correct GTDB taxids for each rank.
"""
import pandas as pd
from tqdm import tqdm

def parse_names_dmp(names_dmp_file):
    """Parse names.dmp into {taxon_name: gtdb_taxid} lookup."""
    name_to_taxid = {}
    with open(names_dmp_file) as f:
        for line in f:
            parts = [p.strip() for p in line.split('|')]
            if len(parts) >= 4 and parts[3] == 'scientific name':
                taxid = parts[0]
                name  = parts[1]
                name_to_taxid[name] = taxid
    print(f"Loaded {len(name_to_taxid)} entries from names.dmp")
    return name_to_taxid

print("Reading names.dmp...")
name_to_taxid = parse_names_dmp(snakemake.params.names_dmp)

print("Reading metadata files...")
cols = ['accession', 'gtdb_representative', 'gtdb_taxonomy']

ar_meta  = pd.read_csv(snakemake.params.ar_metadata,  sep='\t', usecols=cols, low_memory=False)
bac_meta = pd.read_csv(snakemake.params.bac_metadata, sep='\t', usecols=cols, low_memory=False)

meta = pd.concat([ar_meta, bac_meta], ignore_index=True)

# Filter to representative genomes only
reps = meta[meta['gtdb_representative'] == 't'].copy()
reps = reps.dropna(subset=['gtdb_taxonomy'])
print(f"Using {len(reps)} representative genomes")

# Rank setup
rank_order = ['superkingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species']

rank_codes = {
    'd': 'superkingdom', 'p': 'phylum', 'c': 'class',
    'o': 'order',        'f': 'family', 'g': 'genus', 's': 'species'
}

truncate_at = {
    'superkingdom': ';p__',
    'phylum':       ';c__',
    'class':        ';o__',
    'order':        ';f__',
    'family':       ';g__',
    'genus':        ';s__',
    'species':      None
}

def parse_gtdb_taxonomy(tax_string):
    """Parse GTDB taxonomy string into {rank: taxon_name} dict."""
    parsed = {}
    for part in tax_string.split(';'):
        if '__' in part:
            code, taxon = part.split('__', 1)
            code = code.strip()
            if code in rank_codes and taxon.strip():
                parsed[rank_codes[code]] = taxon.strip()
    return parsed

def truncate_lca(tax_string, rank):
    """Truncate a GTDB taxonomy string at the given rank."""
    cutoff = truncate_at[rank]
    if cutoff is None:
        return tax_string.strip()
    return tax_string.split(cutoff)[0].strip()

print("Building LCA table...")
output_rows = []
missing_taxid = 0

for _, row in tqdm(reps.iterrows(), total=len(reps), desc='Processing'):
    taxonomy = row['gtdb_taxonomy']

    if pd.isna(taxonomy):
        continue

    parsed = parse_gtdb_taxonomy(taxonomy)

    for rank in rank_order:
        if rank not in parsed:
            continue

        taxon_name = parsed[rank]

        # Look up correct GTDB taxid from names.dmp
        if taxon_name not in name_to_taxid:
            missing_taxid += 1
            continue

        taxid      = name_to_taxid[taxon_name]
        lca_string = truncate_lca(taxonomy, rank)

        output_rows.append({
            'taxID': taxid,
            'name':  taxon_name,
            'rank':  rank,
            'lca':   lca_string
        })

print(f"\nCreated {len(output_rows)} rows before deduplication")
if missing_taxid > 0:
    print(f"Warning: {missing_taxid} taxon/rank combinations had no entry in names.dmp")

output_df = pd.DataFrame(output_rows)
output_df = output_df.drop_duplicates(subset=['name', 'rank'], keep='first')
output_df = output_df.sort_values('taxID')

output_df.to_csv(snakemake.output[0], index=False)
print(f"Wrote {len(output_df)} unique entries to {snakemake.output[0]}")
print(f"\nBreakdown by rank:")
print(output_df['rank'].value_counts().sort_index())