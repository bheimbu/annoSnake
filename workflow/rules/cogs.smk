localrules: cogs, blastp2, blastp3, blastp4, salmon_index_cogs1

rule cogs:
    input:
        expand(OUTDIR/ "taxonomy/fetchmg/.{sample}_completed", sample=SAMPLES)
    output:
        OUTDIR/ "taxonomy/cogs/{cog}/{cog}.faa"
    shell:
        """
        mkdir -p {OUTDIR}/taxonomy/cogs
        cat {OUTDIR}/taxonomy/fetchmg/*/{wildcards.cog}.faa >> {output}
        """

rule blastp1:
    input:
        faa=OUTDIR/ "taxonomy/cogs/{cog}/{cog}.faa",
        gtdb="databases/gtdb/.setup_done"
    output:
        touch(OUTDIR/ "taxonomy/blastp/{cog}/.{cog}_completed")
    params:
        db=lambda w, input: os.path.dirname(input[1]),
        evalue=config["blastp_evalue"]
    threads:
        20
    conda:
        "envs/environment.yaml"
    shell:
        """
        mkdir -p {OUTDIR}/taxonomy/blastp
        if ! diamond blastp --db {params.db}/gtdb_vers202.dmnd --query {input.faa} --outfmt 102 --out {OUTDIR}/taxonomy/blastp/{wildcards.cog}/{wildcards.cog}.blastp --max-hsps 0 --evalue {params.evalue} --threads {threads}; then
            touch "{OUTDIR}/taxonomy/blastp/{wildcards.cog}/.{wildcards.cog}_completed";
        fi
		"""

rule blastp2:
    input:
        expand(OUTDIR/ "taxonomy/blastp/{cog}/.{cog}_completed", cog=cogs_data['cogs'])
    output:
        matches=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches",
        gtf=OUTDIR/ "taxonomy/cogs/cogs.gtf"
    shell:
        """
        cat {OUTDIR}/taxonomy/prokka/*/*.gtf >> {output.gtf}
        cat {OUTDIR}/taxonomy/blastp/*/*.blastp >> {OUTDIR}/taxonomy/cogs/cogs.blastp 
        awk '$2!=0 {{print $0}}' {OUTDIR}/taxonomy/cogs/cogs.blastp > {output.matches}
        """

rule blastp3:
    input:
        input=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches"
    output:
        output=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca"
    params:
        lca="databases/gtdb/gtdb_vers202_lca.csv",
        evalue=config["blastp_evalue"]		
    conda:
        "envs/environment.yaml"
    script:
        "scripts/gtdb_diamond_lca.R"

rule blastp4:
    input:
        OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca"
    output:
        header=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca.microbes.headers",
        microbes=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca.microbes"
    shell:
        """
        grep "d__" {input} > {output.microbes}
        awk -F"," '{{print $3}}' {output.microbes} | sed 's/"//g' > {output.header}
        """

rule salmon_index_cogs1:
    input:
        OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca.microbes.headers"
    output:
        OUTDIR/ "taxonomy/cogs/cogs.protein_contigs"
    conda:
        "envs/environment.yaml"
    shell:
        """
        scripts/bed_conversion.sh {input} {OUTDIR}/taxonomy/cogs/cogs.gtf {OUTDIR}/taxonomy/cogs/cogs.bed
        cat {OUTDIR}/taxonomy/prokka/*/*.fsa >> {OUTDIR}/taxonomy/cogs/cogs.fsa
        seqtk subseq {OUTDIR}/taxonomy/cogs/cogs.fsa {OUTDIR}/taxonomy/cogs/cogs.bed > {output}
        """
		
rule salmon_index_cogs2:
    input:
        OUTDIR/ "taxonomy/cogs/cogs.protein_contigs"
    output:
        directory(OUTDIR/ "quantification/cogs/cogs.index")
    threads:
        20
    conda:
        "envs/salmon.yaml"
    shell:
        """
        salmon index -p {threads} -t {input} -i {output}
        """