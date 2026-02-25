localrules: cazy2

rule cazy1:
    input:
        gtf=OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf",
        db_setup="databases/cazymes/.setup_done"
    output:
        out=temp(OUTDIR/ "{sample}.out"),
        perseq=temp(OUTDIR/ "{sample}.perseq"),
        perdomain=temp(OUTDIR/ "{sample}.perdomain")		
    conda:
        "envs/environment.yaml"
    params:
        db="databases/cazymes/dbCAN-fam-HMMs.txt",
        evalue=config["cazy_evalue"]
    threads:
        20
    shell:
        """
        hmmscan -E {params.evalue} --cpu {threads} -o {output.out} --tblout {output.perseq} --domtblout {output.perdomain} {params.db} {OUTDIR}/taxonomy/prokka/{wildcards.sample}/{wildcards.sample}.faa			
        """
		
rule cazy2:
    input:
        OUTDIR/ "{sample}.perdomain"
    output:
        OUTDIR/ "annotation/cazy/{sample}/{sample}.dbcan"
    conda:
        "envs/environment.yaml"
    params:
        hmmscanparser="rules/scripts/hmmscan-parser.sh",
        evalue=config["cazy_evalue"]
    shell:
        """
        if [ -s {OUTDIR}/{wildcards.sample}.perdomain ]; then
            {params.hmmscanparser} {OUTDIR}/{wildcards.sample}.perdomain > {OUTDIR}/annotation/cazy/{wildcards.sample}/{wildcards.sample}.dbcan
        fi			
        """
