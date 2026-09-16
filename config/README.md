# Configuration

annoSnake's configuration is documented in full at https://annosnake.readthedocs.io/en/latest/step_by_step.html.

## Quick reference

- config/params.yaml -- workflow parameters: input/output directories, library type (paired-end or interleaved), MAG assembly toggle and completeness/contamination thresholds, which functional annotation databases to run (PFAM, COG, KEGG, CAZYMES), and per-database E-value cutoffs.
- config/config.yaml -- SLURM/cluster execution settings (partition, memory, time limits, job concurrency). Adjust to match your own HPC environment.

Run the workflow from the repository root:

snakemake --profile config/ -n

## Input data

Place gzipped FASTQ files in the directory specified by inputdir in config/params.yaml (relative to the repository root). Sample names are inferred automatically from filenames -- no sample sheet is required.

Paired-end:                Interleaved:
{inputdir}/                {inputdir}/
sample1_R1.fastq.gz        sample1.fastq.gz
sample1_R2.fastq.gz        sample2.fastq.gz
...                        ...

Reads do not need to be pre-trimmed or filtered.

See the full documentation for details on each configuration option, the annotation databases used (https://annosnake.readthedocs.io/en/latest/databases.html), and expected output structure (https://annosnake.readthedocs.io/en/latest/output_overview.html).
