from pathlib import Path
import textwrap
import yaml

configfile: "profile/params.yaml"

with open('rules/scripts/.cogs.yaml', 'r') as file:
    cogs_data = yaml.safe_load(file)
	
	
include: "rules/workflow.smk"

rule all:
    input:
         unpack(setup)

if config["library_type"] == "paired-end":
    include: "rules/megahit_paired_end.smk"
    include: "rules/mag_assembly_paired_end.smk"
    include: "rules/mag_checkm_paired_end.smk"
    include: "rules/salmon_quant_cogs_paired_end.smk"
    include: "rules/salmon_quant_contigs_paired_end.smk"
elif config["library_type"] == "interleaved": 
    include: "rules/megahit_interleaved.smk"
    include: "rules/mag_assembly_interleaved.smk"
    include: "rules/mag_checkm_interleaved.smk"
    include: "rules/salmon_quant_cogs_interleaved.smk"
    include: "rules/salmon_quant_contigs_interleaved.smk"

include: "rules/setup_databases.smk"
include: "rules/mag_prokka.smk"
include: "rules/mag_microbeannotator.smk"
include: "rules/mag_gtdbtk.smk"
#include: "rules/mag_annotree.smk"
include: "rules/metaquast.smk"
include: "rules/prokka.smk"
include: "rules/cazy.smk"
include: "rules/kegg.smk"
include: "rules/pfam.smk"
include: "rules/fetchmg.smk"
include: "rules/cogs.smk"
include: "rules/blastx.smk"
include: "rules/salmon_index_contigs.smk"
include: "rules/combine.smk"
include: "rules/visualization.smk"


onstart:
    print("######## Starting workflow for: ########\n")
    print(SAMPLES)


onsuccess:
    print("Workflow finished, no error")


onerror:
    print("An error occurred")