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
        scripts/bed_conversion.sh {input.headers} {input.gtf} {params.prokka}/{wildcards.sample}.bed
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