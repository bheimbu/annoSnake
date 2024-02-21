localrules: salmon_index_contigs1

rule salmon_index_contigs1:
    input:
        headers=OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches.lca.microbes.headers",
        gtf=OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf"
    output:
        OUTDIR/ "quantification/contigs/{sample}/{sample}.protein_contigs"
    params:
        prokka=lambda wildcards, input: Path(input["gtf"]).parent
    conda:
        "envs/environment.yaml"
    shell:
        """
        sample=$(basename {input.gtf} .gtf) && filtered_gtf_file="$sample"_filtered.gtf && grep -w -f {input.headers} {input.gtf} > "$filtered_gtf_file" && awk 'BEGIN {{OFS="\t"}} !seen[$1]++ {{split($9, a, "gene_id "); gsub(/;/, "", a[2]); print $1, $4 - 1, $5, a[2], $7}}' "$filtered_gtf_file" > {params.prokka}/{wildcards.sample}.bed && rm "$filtered_gtf_file"
        seqtk subseq {params.prokka}/{wildcards.sample}.fsa {params.prokka}/{wildcards.sample}.bed > {output}
        """

rule salmon_index_contigs2:
    input:
        OUTDIR/ "quantification/contigs/{sample}/{sample}.protein_contigs"
    output:
        directory(OUTDIR/ "quantification/contigs/{sample}/{sample}.index")
    threads:
        20
    conda:
        "envs/salmon.yaml"
    shell:
        """
        salmon index -p {threads} -t {input} -i {output}
        """
