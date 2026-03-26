localrules: split_fetchmg_cogs, cogs, blastp2, blastp3, blastp4, salmon_index_cogs1

rule split_fetchmg_cogs:
    input:
        done=OUTDIR / "taxonomy/fetchmg/{sample}/.rule_completed"
    output:
        expand(OUTDIR / "taxonomy/fetchmg/{{sample}}/{cog}.faa", cog=COGS)
    params:
        cogs=" ".join(COGS)
    conda:
        "envs/seqkit.yaml"
    benchmark:
        OUTDIR/ "benchmarks/{sample}_split_fetchmg_cogs.txt"
    shell:
        """
        set -euo pipefail
        outdir="{OUTDIR}/taxonomy/fetchmg/{wildcards.sample}"
        mkdir -p "$outdir"
        COG_LIST="{params.cogs}"
        for cog in $COG_LIST; do
            : > "$outdir/${{cog}}.faa"
        done
        if [ ! -s "{OUTDIR}/taxonomy/fetchmg/{wildcards.sample}/{wildcards.sample}.faa.fetchMGs.scores" ] || [ "$(wc -l < "{OUTDIR}/taxonomy/fetchmg/{wildcards.sample}/{wildcards.sample}.faa.fetchMGs.scores")" -le 1 ]; then
            exit 0
        fi
        tmpdir="$(mktemp -d)"
        trap 'rm -rf "$tmpdir"' EXIT
        awk 'NR>1 && $3 ~ /^COG/ {{print $1 > ("'"$tmpdir"'/" $3 ".ids")}}' "{OUTDIR}/taxonomy/fetchmg/{wildcards.sample}/{wildcards.sample}.faa.fetchMGs.scores"
        for ids in "$tmpdir"/COG*.ids; do
            [ -e "$ids" ] || continue
            cog="$(basename "$ids" .ids)"
            seqkit grep -r -f "$ids" "{OUTDIR}/taxonomy/fetchmg/{wildcards.sample}/{wildcards.sample}.faa.fetchMGs.faa" > "$outdir/${{cog}}.faa" || true
        done
        """

rule cogs:
    input:
        gtdb_done="databases/gtdb/.setup_done",
        per_sample = lambda wildcards: expand(OUTDIR / "taxonomy/fetchmg/{sample}/{cog}.faa", sample=SAMPLES, cog=wildcards.cog)
    output:
        OUTDIR/ "taxonomy/cogs/{cog}/{cog}.faa"
    shell:
        """
        mkdir -p {OUTDIR}/taxonomy/cogs
        cat {input.per_sample} > {output}
        """

rule blastp1:
    input:
        faa=OUTDIR/ "taxonomy/cogs/{cog}/{cog}.faa",
        gtdb="databases/gtdb/.setup_done"
    output:
        touch(OUTDIR/ "taxonomy/blastp/{cog}/.{cog}_completed")
    params:
        db=lambda wildcards, input: Path(input["gtdb"]).parent,
        evalue=config["blastp_evalue"]
    threads:
        20
    conda:
        "envs/environment.yaml"
    benchmark:
        OUTDIR/ "benchmarks/{cog}_blastp1.txt"
    shell:
        """
        mkdir -p {OUTDIR}/taxonomy/blastp
        if ! diamond blastp --ultra-sensitive --db {params.db}/*.dmnd --query {input.faa} --outfmt 102 --out {OUTDIR}/taxonomy/blastp/{wildcards.cog}/{wildcards.cog}.blastp --max-hsps 0 --evalue {params.evalue} --threads {threads}; then
            touch "{OUTDIR}/taxonomy/blastp/{wildcards.cog}/.{wildcards.cog}_completed";
        fi
        """

rule blastp2:
    input:
        expand(OUTDIR/ "taxonomy/blastp/{cog}/.{cog}_completed", cog=cogs_data['cogs'])
    output:
        matches=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches",
        gtf=OUTDIR/ "taxonomy/cogs/cogs.gtf"
    benchmark:
        OUTDIR/ "benchmarks/blastp2.txt"
    shell:
        """
        cat {OUTDIR}/taxonomy/prokka/*/*.gtf >> {output.gtf}
        cat {OUTDIR}/taxonomy/blastp/*/*.blastp >> {OUTDIR}/taxonomy/cogs/cogs.blastp 
        awk '$2!=0 {{print $0}}' {OUTDIR}/taxonomy/cogs/cogs.blastp > {output.matches}
        """

rule blastp3:
    input:
        input=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches",
        gtdb="databases/gtdb/.setup_done"
    output:
        output=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca"
    params:
        lca="databases/gtdb/gtdb_latest_lca.csv",
        evalue=config["blastp_evalue"]
    conda:
        "envs/environment.yaml"
    benchmark:
        OUTDIR/ "benchmarks/blastp3.txt"
    script:
        "scripts/gtdb_diamond_lca.R"

rule blastp4:
    input:
        OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca"
    output:
        header=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca.microbes.headers",
        microbes=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca.microbes"
    benchmark:
        OUTDIR/ "benchmarks/blastp4.txt"
    shell:
        """
        grep "d__" {input} > {output.microbes}
        awk -F"," '{{print $2}}' {output.microbes} | sed 's/"//g' | cut -d '.' -f1 > {output.header}
        """

rule salmon_index_cogs1:
    input:
        headers=OUTDIR/ "taxonomy/cogs/cogs.blastp.matches.lca.microbes.headers",
        gtf=OUTDIR/ "taxonomy/cogs/cogs.gtf"
    output:
        OUTDIR/ "taxonomy/cogs/cogs.protein_contigs"
    params:
        bed=lambda wildcards, input: Path(input["gtf"]).parent
    conda:
        "envs/seqtk.yaml"
    benchmark:
        OUTDIR/ "benchmarks/salmon_index_cogs1.txt"
    shell:
        """
        sample=$(basename {input.gtf} .gtf) && filtered_gtf_file="$sample"_filtered.gtf && grep -w -f {input.headers} {input.gtf} > "$filtered_gtf_file" && awk 'BEGIN {{OFS="\t"}} !seen[$1]++ {{split($9, a, "gene_id "); gsub(/;/, "", a[2]); print $1, $4 - 1, $5, a[2], $7}}' "$filtered_gtf_file" > {params.bed}/cogs.bed && rm "$filtered_gtf_file"        
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
    benchmark:
        OUTDIR/ "benchmarks/salmon_index_cogs2.txt"
    shell:
        """
        salmon index -p {threads} -t {input} -i {output}
        """
