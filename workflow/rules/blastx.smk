localrules: blastx2, blastx3, blastx4

rule blastx1:
    input:
        gtf=OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf",
        db_setup="databases/gtdb/.setup_done"
    output:
        OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx"
    params:
        db=lambda wildcards, input: Path(input["db_setup"]).parent,
        fna=lambda wildcards, input: Path(input["gtf"]).parent,
        evalue=config["blastx_evalue"]
    threads:
        40
    conda:
        "envs/environment.yaml"
    benchmark:
        "benchmarks/{sample}_blastx1.txt"
    shell:
        """
        diamond blastx --db {params.db}/*.dmnd --query {params.fna}/{wildcards.sample}.fna --outfmt 102 --out {output} --max-hsps 0 --evalue {params.evalue} --threads {threads}
        """
		
rule blastx2:
    input:
        OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx"
    output:
        OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches"
    conda:
        "envs/environment.yaml"
    benchmark:
        "benchmarks/{sample}_blastx2.txt"
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
    params:
        lca="databases/gtdb/gtdb_latest_lca.csv",
        evalue=config["blastx_evalue"]
    conda:
        "envs/environment.yaml"
    benchmark:
        "benchmarks/{sample}_blastx3.txt"
    script:
        "scripts/gtdb_diamond_lca.R"
		
rule blastx4:
    input:
        OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches.lca"
    output:
        microbes=OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches.lca.microbes",
        headers=OUTDIR/ "taxonomy/blastx/{sample}/{sample}.blastx.matches.lca.microbes.headers"
    conda:
        "envs/environment.yaml"
    benchmark:
        "benchmarks/{sample}_blastx4.txt"
    shell:
        """
        grep "d__" {input} > {output.microbes}
        awk -F"," '{{print $2}}' {output.microbes} | sed 's/"//g' > {output.headers}
        """        
