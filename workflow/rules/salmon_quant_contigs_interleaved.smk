rule salmon_quant_contigs_interleaved:
    input:
        OUTDIR/ "quantification/contigs/{sample}/{sample}.index"
    output:
        touch(OUTDIR/ "quantification/contigs/{sample}/.rule_completed")
    params:
        contigs=lambda wildcards, output: Path(output[0]).parent
    threads:
        20
    conda:
        "envs/salmon.yaml"
    shell:
        """
        rules/scripts/runner.sh salmon quant -i {input} -l IU --interleaved <(gunzip -c {INPUTDIR}/{wildcards.sample}.fastq.gz) -o {params.contigs}/{wildcards.sample}.quant --meta -p {threads}
        """
