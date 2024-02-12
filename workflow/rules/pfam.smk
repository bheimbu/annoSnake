rule pfam:
    input:
        gtf=OUTDIR/ "taxonomy/prokka/{sample}/{sample}.gtf",
        db_setup="databases/pfam/.setup_done"
    output:
        OUTDIR/ "annotation/pfam/{sample}/{sample}.evalue"
    params:
        evalue=config["pfam_evalue"],
        db=lambda wildcards, input: Path(input[1]).parent,
        faa=lambda wildcards, input: Path(input[0]).parent
    threads:
        20
    conda:
        "envs/environment.yaml"
    shell:
        """
        pfam_scan.pl -fasta {params.faa}/{wildcards.sample}.faa -dir {params.db} -e_seq 1e-4 -cpu {threads} |
        awk '$1 !~ /^#/ && $13 < {params.evalue} {{print $0}}' > {output}
        """