localrules: visualization_cogs, visualization_kegg, visualization_mags1, visualization_mags2

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

rule visualization_mags1:
    input:
        OUTDIR/ "MAGs/microbeannotator/.rule_completed"
    params:
        KO_list="rules/scripts/KO_list.txt",
        kofam_results=lambda wildcards, output: Path(output[0]).parent
    output:
        hits=OUTDIR/ "MAGs/microbeannotator/kofam_results/all.hits",
        bins=OUTDIR/ "MAGs/microbeannotator/kofam_results/all.bins"
    conda:
        "envs/visualization.yaml"
    shell:
        """
        grep -E -f {params.KO_list} {params.kofam_results}/*filt > {output.bins}
        sed -i 's|kofam_results/||g' {output.bins}
        awk -F'\t' '{{sub(/\.faa.*/, ".faa", $1); print $1, $3}}' {output.bins} > {output.hits}
        sed -i 's|.faa||g' {output.hits}
        """

rule visualization_mags2:
    input:
        hits=OUTDIR/ "MAGs/microbeannotator/kofam_results/all.hits",
        checkm=OUTDIR/ "MAGs/checkm/checkm_summaries"
    params:
        pathway="rules/scripts/keggid_genes_pathway.csv"
    output:
        pdf=OUTDIR/ "visualization/MAG_metabolic_pathways.pdf"
    conda:
        "envs/visualization.yaml"
    script:
        "scripts/mags_visualize.R"
