localrules: blastx2, blastx3, blastx4

rule blastx1:
    input:
        gtf=OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf",
        db_setup="databases/gtdb/.setup_done"
    output:
        OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx"
    group:
        "blastx"
    params:
        db=lambda wildcards, input: Path(input["db_setup"]).parent,
        fna=lambda wildcards, input: Path(input["gtf"]).parent,
        evalue=config["blastx_evalue"]
    threads:
        40
    conda:
        "envs/environment.yaml"
    shell:
        """
        diamond blastx --db {params.db}/gtdb_vers202.dmnd --query {params.fna}/{wildcards.sample}.fna --outfmt 102 --out {output} --max-hsps 0 --evalue {params.evalue} --threads {threads}
        """
		
rule blastx2:
    input:
        OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx"
    output:
        OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches"
    group:
        "blastx"
    conda:
        "envs/environment.yaml"
    shell:
        """
        if [ -s {OUTDIR}/taxonomy/blastx/{wildcards.sample}/{wildcards.sample}.blastx ]; then
            awk '$2!=0 {{print $0}}' {input} > {output}
        fi
        """
		
rule blastx3:
    input:
        input=OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches",
        db_setup="databases/gtdb/.setup_done"
    output:
        output=OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches.lca"
    group:
        "blastx"
    params:
        lca=lambda wildcards, input: Path(input["db_setup"]).parent,
        evalue=config["blastx_evalue"]
    conda:
        "envs/environment.yaml"
    script:
        "scripts/gtdb_diamond_lca.R"
		
rule blastx4:
    input:
        OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches.lca"
    output:
        microbes=OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches.lca.microbes",
        headers=OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches.lca.microbes.headers"		
    group:
        "blastx"
    conda:
        "envs/environment.yaml"
    shell:
        """
        grep "d__" {input} > {output.microbes}
        awk -F"," '{{print $3}}' {output.microbes} | sed 's/"//g' > {output.headers}
        """        
