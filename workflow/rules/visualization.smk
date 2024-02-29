localrules: visualization_cogs, visualization_kegg

rule visualization_cogs:
    input:
        quant=OUTDIR/ "combine/cogs.sf",
        gtf=OUTDIR/ "taxonomy/cogs/cogs.gtf",
        microbes=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca.microbes"
    output:
        html=OUTDIR/ "visualization/rel_abundance_of_bacteria_and_archaea_in_metagenomes.html"
    conda:
        "envs/visualization.yaml"
    script:
        "scripts/cog_visualize.R"
		
rule visualization_kegg:
    input:
        kegg=OUTDIR/ "combine/kegg_combine.txt",
        gtf=OUTDIR/ "combine/contigs_combine.gtf",
        quant=OUTDIR/ "combine/contigs_combine.sf"
    params:
        keggID="rules/scripts/keggID_to_gene_name.csv"
    output:
        html=OUTDIR/ "visualization/prokaryotic_metabolic_pathways.html"
    conda:
        "envs/visualization.yaml"
    script:
        "scripts/kegg_visualize.R"

rule visualization_methanogenesis:
    input:
        OUTDIR/ "MAGs/checkm/checkm_summaries"
    params:
        KO_list="rules/scripts/methanogenesis_KO_list.txt",
        kofam_results=lambda wildcards, input: Path(input[0]).parent
    output:
        pdf=OUTDIR/ "visualization/methanogenesis.pdf"
    conda:
        "envs/visualization.yaml"
    script:
        "scripts/methanogensis_visualize.R"
