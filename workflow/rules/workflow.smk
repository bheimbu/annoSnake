# workflow.smk

INPUTDIR = Path(config["inputdir"])
OUTDIR = Path(config["outdir"])

if config["library_type"] == "paired-end":
    SAMPLES = set(glob_wildcards(str(INPUTDIR / "{sample}_R1.fastq.gz")).sample)
elif config["library_type"] == "interleaved":
    SAMPLES = set(glob_wildcards(str(INPUTDIR / "{sample}.fastq.gz")).sample)

def setup(sample):
    l = [expand(output, sample=SAMPLES), OUTDIR/ "combine/metaquast.html"]
    return l

output = []

if config["library_type"] == "paired-end":  
    output.append(OUTDIR/ "quantification/contigs/{sample}/.rule_completed")
if config["library_type"] == "interleaved":  
    output.append(OUTDIR/ "quantification/contigs/{sample}/.rule_completed")
if config["mag_assembly"] == True:
    output.append(OUTDIR/ "MAGs/gtdbtk/.rule_completed")
    output.append(OUTDIR/ "MAGs/microbeannotator/.rule_completed")
    output.append(OUTDIR/ "MAGs/checkm/{sample}/.rule_completed")
    output.append("databases/checkm/.setup_done")
    output.append(OUTDIR/ "figures/MAG_metabolic_pathways.pdf")
if config["KEGG"] == True:
    output.append(OUTDIR/ "combine/kegg_combine.txt")	
if config["CAZYMES"] == True:
    output.append(OUTDIR/ "combine/cazy_combine.txt")
    output.append(OUTDIR/ "figures/relative_abundance_CAZymes_metagenomes.html")
    output.append(OUTDIR/ "figures/relative_abundance_CAZymes_metagenomes.pdf")
if config["PFAM"] == True:
    output.append(OUTDIR/ "combine/pfam_combine.txt")	
if config["COG"] == True:
    output.append(OUTDIR/ "combine/cogs.sf")
    output.append(OUTDIR/ "combine/contigs_combine.sf")
    output.append("databases/gtdb/.setup_done")
if config["COG"] == True:
    output.append(OUTDIR/ "figures/rel_abundance_of_bacteria_and_archaea_in_metagenomes.html")
    output.append(OUTDIR/ "figures/rel_abundance_of_bacteria_and_archaea_in_metagenomes.pdf")
if config["KEGG"] == True:
    output.append(OUTDIR/ "figures/prokaryotic_metabolic_pathways.html")
    output.append(OUTDIR/ "figures/prokaryotic_metabolic_pathways.pdf")
    output.append(OUTDIR/ "combine/contigs_combine.gtf")
