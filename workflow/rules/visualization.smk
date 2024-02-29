localrules: visualization_cogs, visualization_kegg, visualization_methanogenesis1, visualization_methanogenesis2

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

rule visualization_methanogenesis1:
    input:
        OUTDIR/ "MAGs/microbeannotator/.rule_completed"
    params:
        KO_list="rules/scripts/methanogenesis_KO_list.txt",
        kofam_results=lambda wildcards, output: Path(output[0]).parent
    output:
        OUTDIR/ "MAGs/microbeannotator/kofam_results/methanogenesis_hits.txt"
    conda:
        "envs/visualization.yaml"
    shell:
        """
        grep -E -f {params.KO_list} {params.kofam_results} | awk -F'\t' '{sub(/\.faa.*/, ".faa", $1); print $1, $3}' > {output}
        ""

rule visualization_methanogenesis2:
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
