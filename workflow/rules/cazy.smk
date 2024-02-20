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
        db=lambda wildcards, input: Path(input[1]).parent
    threads:
        20
    shell:
        """
        hmmscan -E 1.0e-5 --cpu {threads} -o {output.out} --tblout {output.perseq} --domtblout {output.perdomain} {params.db}/dbCAN-fam-HMMs.txt.v11 {OUTDIR}/taxonomy/prokka/{wildcards.sample}/{wildcards.sample}.faa			
        """
		
rule cazy2:
    input:
        OUTDIR/ "{sample}.perdomain"
    output:
        OUTDIR/ "annotation/cazy/{sample}/{sample}.top"
    conda:
        "envs/environment.yaml"
    params:
        hmmscanparser="rules/scripts/hmmscan-parser.sh",
        evalue=config["cazy_evalue"]
    shell:
        """
        if [ -s {OUTDIR}/{wildcards.sample}.perdomain ]; then
            {params.hmmscanparser} {OUTDIR}/{wildcards.sample}.perdomain > {OUTDIR}/annotation/cazy/{wildcards.sample}/{wildcards.sample}.dbcan
            awk -F"\t" '$5<{params.evalue} {{print $2"\t"$3"\t"$4"\t"$5"\t"$10"\t"$1}}' {OUTDIR}/annotation/cazy/{wildcards.sample}/{wildcards.sample}.dbcan > {OUTDIR}/annotation/cazy/{wildcards.sample}/{wildcards.sample}.evalue
            export LC_ALL=C LC_LANG=C; sort -k3,3 -k5,5gr {OUTDIR}/annotation/cazy/{wildcards.sample}/{wildcards.sample}.evalue > {OUTDIR}/annotation/cazy/{wildcards.sample}/{wildcards.sample}.sorted
            for next in $(cut -f2 {OUTDIR}/annotation/cazy/{wildcards.sample}/{wildcards.sample}.sorted | sort | uniq -u); do grep -w -m 1 "$next" {OUTDIR}/annotation/cazy/{wildcards.sample}/{wildcards.sample}.sorted; done > {output}
        fi			
        """
