#!/usr/bin/env python
"""
Snakemake script to convert GTDB to DIAMOND input format.
Uses snakemake object for inputs/outputs instead of argparse.
"""
import os
import sys
import gzip
import tarfile
import shutil
import logging

logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.DEBUG)

def read_taxid_map(taxid_map_file):
    """Read taxonkit taxid.map file: accession -> taxid"""
    taxid_map = {}
    with open(taxid_map_file) as f:
        for line in f:
            if line.startswith('#') or not line.strip():
                continue
            parts = line.strip().split('\t')
            if len(parts) >= 2:
                accession = parts[0]
                taxid = parts[1]
                taxid_map[accession] = taxid
    logging.info(f'Loaded {len(taxid_map)} accessions from taxid.map')
    return taxid_map

def extract_tarball(tarball_path, tmpdir):
    """Extract faa files from tarball"""
    logging.info(f'Extracting {tarball_path}...')
    if not os.path.isdir(tmpdir):
        os.makedirs(tmpdir)
    
    faa_files = {}
    with tarfile.open(tarball_path, 'r:gz') as tar:
        for member in tar.getmembers():
            if member.name.endswith('_protein.faa.gz'):
                # Extract to tmpdir
                tar.extract(member, tmpdir)
                faa_path = os.path.join(tmpdir, member.name)
                
                # Get genome accession from filename
                basename = os.path.basename(member.name)
                # Remove _protein.faa.gz and RS_/GB_ prefix
                accession = basename.replace('_protein.faa.gz', '')
                accession = accession.replace('RS_', '').replace('GB_', '')
                
                faa_files[accession] = faa_path
    
    logging.info(f'Extracted {len(faa_files)} faa files')
    return faa_files

def create_accession2taxid(taxid_map, faa_files, outfile):
    """Create accession2taxid.tsv for DIAMOND"""
    logging.info('Creating accession2taxid.tsv...')
    
    protein_count = 0
    missing_count = 0
    
    with open(outfile, 'w') as out:
        out.write('accession.version\ttaxid\n')
        
        for i, (genome_acc, faa_file) in enumerate(faa_files.items(), 1):
            # Progress every 1000 genomes
            if i % 1000 == 0:
                logging.info(f'Processed {i}/{len(faa_files)} genomes...')
            
            # Get taxid for this genome
            if genome_acc not in taxid_map:
                logging.warning(f'No taxid found for {genome_acc}')
                missing_count += 1
                continue
            
            taxid = taxid_map[genome_acc]
            
            # Read protein IDs from faa file
            opener = gzip.open if faa_file.endswith('.gz') else open
            with opener(faa_file, 'rt') as f:
                for line in f:
                    if line.startswith('>'):
                        protein_id = line[1:].split()[0]
                        out.write(f'{protein_id}\t{taxid}\n')
                        protein_count += 1
    
    logging.info(f'Wrote {protein_count} protein->taxid mappings to {outfile}')
    if missing_count > 0:
        logging.warning(f'{missing_count} genomes had no taxid mapping')

def main():
    # Access Snakemake variables
    tarball = snakemake.params.tarball
    taxid_map_file = snakemake.input.taxid_map
    names_dmp = snakemake.params.names
    nodes_dmp = snakemake.params.nodes
    
    acc2tax_out = snakemake.output.acc2tax
    names_out = snakemake.output.names_out
    nodes_out = snakemake.output.nodes_out
    
    tmpdir = snakemake.params.tmpdir
    
    # Create output directory
    outdir = os.path.dirname(acc2tax_out)
    if not os.path.isdir(outdir):
        os.makedirs(outdir)
    
    # Copy nodes.dmp and names.dmp to output
    shutil.copy(nodes_dmp, nodes_out)
    shutil.copy(names_dmp, names_out)
    logging.info(f'Copied taxdump files to {outdir}')
    
    # Read taxid map
    taxid_map = read_taxid_map(taxid_map_file)
    
    # Extract faa files
    faa_files = extract_tarball(tarball, tmpdir)
    
    # Create accession2taxid
    create_accession2taxid(taxid_map, faa_files, acc2tax_out)
    
    logging.info(f'Done! Temporary files in {tmpdir}')
    logging.info(f'Run merge step to create gtdb_all.faa.gz from {tmpdir}')

if __name__ == '__main__':
    main()