localrules: kegg2

rule kegg1:
    input:
        gtf=OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf",
        db_setup="databases/kegg/.setup_done"
    output:
        temp(OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.detail")
    params:
        db=lambda wildcards, input: Path(input[1]).parent,
        tmp=lambda wildcards, output: Path(output[0]).parent,
    threads:
        20
    conda:
        "envs/environment.yaml"
    shell:
        """
        exec_annotation -o {output} --tmp-dir {params.tmp} -p {params.db}/profiles -k {params.db}/ko_list --cpu {threads} -f detail-tsv {OUTDIR}/taxonomy/prokka/{wildcards.sample}/{wildcards.sample}.faa
        """
		
rule kegg2:
    input:
        input=OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.detail",
        db_setup="databases/kegg/.setup_done"
    output:
        touch(OUTDIR/ "annotation/kegg/{sample}/.rule_completed"),
        selected=temp(OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.selected"),
        evalue=OUTDIR/ "annotation/kegg/{sample}/{sample}.kegg.evalue"
    params:
        db=lambda wildcards, input: Path(input["db_setup"]).parent
    conda:
        "envs/environment.yaml"
    script:
        "scripts/kegg.R"
