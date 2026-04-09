localrules: MAG_checkm2_paired, MAG_checkm2_bins, MAG_above_threshold_bins

rule MAG_metabat2:
    input:
        OUTDIR/ "assemblies/preprocessed_contigs/{sample}/.rule_completed"
    output:
        touch(OUTDIR/ "MAGs/metabat2/{sample}/.rule_completed")
    shadow:
       "shallow"
    params:
        min_length=config['min_length'],
        fna=lambda w, input: Path(input[0]).parent,
        dir=lambda w, output: Path(output[0]).parent
    threads:
        40
    conda:
        "envs/mags.yaml"
    benchmark:
        OUTDIR/ "benchmarks/{sample}_MAG_metabat2.txt"
    shell:
        """
        bowtie2-build {params.fna}/{wildcards.sample}.fna {params.fna}/{wildcards.sample}.fna
        bowtie2 -x {params.fna}/{wildcards.sample}.fna -p {threads} -1 {INPUTDIR}/{wildcards.sample}_R1.fastq.gz -2 {INPUTDIR}/{wildcards.sample}_R2.fastq.gz | samtools view -@{threads} -bS -o {params.fna}/{wildcards.sample}.bam
        samtools sort -@{threads} {params.fna}/{wildcards.sample}.bam -o {params.fna}/{wildcards.sample}.sort
        samtools index -@{threads} {params.fna}/{wildcards.sample}.sort
        runMetaBat.sh -m {params.min_length} {params.fna}/{wildcards.sample}.fna {params.fna}/{wildcards.sample}.sort
        rm -rf {params.fna}/{wildcards.sample}.sort* {params.fna}/{wildcards.sample}.bam
        mkdir -p {params.dir}
        mv {wildcards.sample}.fna.* {params.dir}
        """

rule MAG_metacoag:
     input:
        OUTDIR/ "assemblies/preprocessed_contigs/{sample}/.rule_completed"
     output:
        touch(OUTDIR/ "MAGs/metacoag/{sample}/.rule_completed"),
        gfa=temp(OUTDIR/ "MAGs/metacoag/{sample}/{sample}.gfa"),
        abundance=temp(OUTDIR/ "MAGs/metacoag/{sample}/{sample}.abundance.tsv"),
        fastg=temp(OUTDIR/ "MAGs/metacoag/{sample}/{sample}.fastg"),
        dir=directory(OUTDIR/ "MAGs/metacoag/{sample}")
     shadow:
        "shallow"
     params:
        contigs=lambda wildcards, input: Path(input[0]).parent
     threads:
        20
     conda:
        "envs/mags.yaml"
     benchmark:
        OUTDIR/ "benchmarks/{sample}_MAG_metacoag.txt"
     shell:
        """
        coverm contig -1 {INPUTDIR}/{wildcards.sample}_R1.fastq.gz -2 {INPUTDIR}/{wildcards.sample}_R2.fastq.gz -r {params.contigs}/{wildcards.sample}.fna -o {output.abundance} -t {threads} 
        sed -i '1d' {output.abundance}
        megahit_core contig2fastg 141 {params.contigs}/{wildcards.sample}.fna > {output.fastg}
        fastg2gfa {output.fastg} > {output.gfa}
        if ! metacoag --assembler megahit --graph {output.gfa} --contigs {params.contigs}/{wildcards.sample}.fna --abundance {output.abundance} --output {output.dir}  --nthreads {threads}; then
            mkdir -p {output.dir}/bins && touch {output[0]}
        fi
        """

rule MAG_maxbin2:
      input:
        OUTDIR/ "assemblies/preprocessed_contigs/{sample}/.rule_completed"
      output:
        touch(OUTDIR/ "MAGs/maxbin2/{sample}/.rule_completed")
      threads:
        20
      params:
        fna=lambda w, input: Path(input[0]).parent,
        dir=lambda w, output: Path(output[0]).parent
      shadow:
        "shallow"
      conda:
        "envs/mags.yaml"
      benchmark:
        OUTDIR/ "benchmarks/{sample}_MAG_maxbin2.txt"
      shell:
        """
        if ! run_MaxBin.pl -contig {params.fna}/{wildcards.sample}.fna -reads {INPUTDIR}/{wildcards.sample}_R1.fastq.gz -reads2 {INPUTDIR}/{wildcards.sample}_R2.fastq.gz -thread {threads} -out {wildcards.sample}; then
             touch {output[0]}
        else
             mkdir -p {params.dir}/bins && mv *.fasta {params.dir}/bins/
        fi
        """

rule MAG_refinement:
      input:
        metabat2=OUTDIR/ "MAGs/metabat2/{sample}/.rule_completed",
        metacoag=OUTDIR/ "MAGs/metacoag/{sample}/.rule_completed",
        maxbin2=OUTDIR/ "MAGs/maxbin2/{sample}/.rule_completed"
      output:
        touch(OUTDIR/ "MAGs/bin_refinement/{sample}/.rule_completed")
      params:
        completeness=10,
        contamination=90,
        metabat2=lambda w, input: Path(input["metabat2"]).parent,
        metacoag=lambda w, input: Path(input["metacoag"]).parent,
        maxbin2=lambda w, input: Path(input["maxbin2"]).parent,
        dir=lambda w, output: Path(output[0]).parent
      threads:
        20
      conda:
        "envs/metawrap.yaml"
      benchmark:
        OUTDIR/ "benchmarks/{sample}_MAG_refinement.txt"
      shell:
        """      
        if [ "$(find {params.metabat2}/{wildcards.sample}.fna.metabat-bins* -type f -name '*.fa' | wc -l)" -gt 0 ] &&
           [ "$(find {params.maxbin2}/bins -type f -name '*.fasta' | wc -l)" -gt 0 ] &&
           [ "$(find {params.metacoag}/bins -type f -name '*.fasta' | wc -l)" -gt 0 ]; then
            if ! metawrap bin_refinement -o {params.dir} -t {threads} -A {params.metabat2}/{wildcards.sample}.fna.metabat-bins* -B {params.maxbin2}/bins -C {params.metacoag}/bins -c {params.completeness} -x {params.contamination}; then
                touch {output[0]};
            fi    
        elif [ "$(find {params.metabat2}/{wildcards.sample}.fna.metabat-bins* -type f -name '*.fa' | wc -l)" -gt 0 ] &&
             [ "$(find {params.maxbin2}/bins -type f -name '*.fasta' | wc -l)" -gt 0 ]; then
            if ! metawrap bin_refinement -o {params.dir} -t {threads} -A {params.metabat2}/{wildcards.sample}.fna.metabat-bins* -B {params.maxbin2}/bins -c {params.completeness} -x {params.contamination}; then
                touch {output[0]};
            fi    
        elif [ "$(find {params.metabat2}/{wildcards.sample}.fna.metabat-bins* -type f -name '*.fa' | wc -l)" -gt 0 ] &&
             [ "$(find {params.metacoag}/bins -type f -name '*.fasta' | wc -l)" -gt 0 ]; then
            if ! metawrap bin_refinement -o {params.dir} -t {threads} -A {params.metabat2}/{wildcards.sample}.fna.metabat-bins* -B {params.metacoag}/bins -c {params.completeness} -x {params.contamination}; then
                touch {output[0]};
            fi    
        elif [ "$(find {params.maxbin2}/bins -type f -name '*.fasta' | wc -l)" -gt 0 ] &&
             [ "$(find {params.metacoag}/bins -type f -name '*.fasta' | wc -l)" -gt 0 ]; then
            if ! metawrap bin_refinement -o {params.dir} -t {threads} -A {params.maxbin2}/bins -B {params.metacoag}/bins -c {params.completeness} -x {params.contamination}; then
                touch {output[0]};
            fi    
        else
           touch {output[0]}
        fi
        """

rule MAG_checkm2_bins:
      input:
        expand(OUTDIR/ "MAGs/bin_refinement/{sample}/.rule_completed", sample=SAMPLES)
      output:
        touch(OUTDIR/ "MAGs/checkm2/bins/.rule_completed")
      benchmark:
        OUTDIR/ "benchmarks/MAG_checkm2/bins.txt"
      shell:
        """  
        rm -rf {OUTDIR}/MAGs/metacoag/*pickle
        if [ ! -d {OUTDIR}/MAGs/checkm2/bins ]; then
          mkdir -p {OUTDIR}/MAGs/checkm2/bins
        fi
        for dir in {OUTDIR}/MAGs/bin_refinement/*/; do
          if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")
            bin_dir=$(find "$dir" -maxdepth 1 -type d -name 'metawrap_*_bins' -print -quit)
            for file in "$bin_dir"/*; do
              if [ -f "$file" ]; then
                base_name=$(basename "$file")
                new_name="$dir_name"_"$base_name"
                mkdir -p {OUTDIR}/MAGs/checkm2/bins/"$dir_name"/
				cp "$file" {OUTDIR}/MAGs/checkm2/bins/"$dir_name"/"$new_name"
              fi
            done
          fi
        done
        """

rule MAG_checkm2:
    input:
        OUTDIR/ "MAGs/checkm2/bins/.rule_completed",
        "databases/checkm2/.setup_done"
    output:
        touch(OUTDIR/ "MAGs/checkm2/quality_report/{sample}/.rule_completed")
    params:
        db="databases/checkm2/CheckM2_database/uniref100.KO.1.dmnd",
    threads:
        40
    conda:
        "envs/checkm2.yaml"
    benchmark:
        OUTDIR/ "benchmarks/{sample}_MAG_checkm2.txt"
    shell:
        """
        if [ -e {OUTDIR}/MAGs/checkm2/bins/{wildcards.sample}/{wildcards.sample}_bin.1.fa ]; then
            checkm2 predict --threads {threads} --extension .fa \
                --input {OUTDIR}/MAGs/checkm2/bins/{wildcards.sample} \
                --output-directory {OUTDIR}/MAGs/checkm2/quality_report/{wildcards.sample} \
                --database_path {params.db} --force
        else
            touch "{OUTDIR}/MAGs/checkm2/quality_report/{wildcards.sample}/.rule_completed"
        fi
        """


rule MAG_above_threshold_bins:
    input:
        OUTDIR/ "MAGs/checkm2/quality_report/{sample}/.rule_completed"
    output:
        touch(OUTDIR/ "MAGs/above_threshold_bins/{sample}/.rule_completed")
    params:
        completeness=config['completeness'],
        contamination=config['contamination']
    benchmark:
        OUTDIR/ "benchmarks/{sample}_MAG_above_threshold_bins.txt"
    shell:
        """
        tsv="{OUTDIR}/MAGs/checkm2/quality_report/{wildcards.sample}/quality_report.tsv"

        if [ -f "$tsv" ]; then
            mkdir -p {OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample}
            awk -F'\\t' 'NR>1 && $2>{params.completeness} && $3<{params.contamination} {{print $1}}' "$tsv" | \
            while read bin_name; do
                src="{OUTDIR}/MAGs/checkm2/bins/{wildcards.sample}/${{bin_name}}.fa"
                if [ -f "$src" ]; then
                    cp "$src" {OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample}/
                else
                    echo "Warning: $src not found, skipping"
                fi
            done
        else
            touch "{OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample}/.rule_completed"
        fi
        """

rule MAG_coverm:
      input:
        OUTDIR/ "MAGs/above_threshold_bins/{sample}/.rule_completed"
      output:
        touch(OUTDIR/ "MAGs/coverm/{sample}/.rule_completed")
      threads:
        40
      conda:
        "envs/checkm2.yaml"
      benchmark:
        OUTDIR/ "benchmarks/{sample}_coverm.txt"
      shell:
        """
        if compgen -G "{OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample}/*.fa" > /dev/null; then
            coverm genome --coupled {INPUTDIR}/{wildcards.sample}_R1.fastq.gz {INPUTDIR}/{wildcards.sample}_R2.fastq.gz --genome-fasta-files {OUTDIR}/MAGs/above_threshold_bins/{wildcards.sample}/*.fa --threads {threads} >& {OUTDIR}/MAGs/coverm/{wildcards.sample}/{wildcards.sample}.abundance
        else
            touch "{OUTDIR}/MAGs/coverm/{wildcards.sample}/.rule_completed"
        fi
        """

rule MAG_checkm2_paired:
      input:
        expand(OUTDIR/ "MAGs/above_threshold_bins/{sample}/.rule_completed", sample=SAMPLES)
      output:
        directory(OUTDIR / "MAGs/checkm2/summaries")
      params:
        indir=OUTDIR / "MAGs/checkm2/quality_report",
        samples=" ".join(SAMPLES)
      benchmark:
        OUTDIR/ "benchmarks/MAG_checkm2_paired.txt"
      shell:
        """
        mkdir -p {output}
        find {params.indir} -maxdepth 2 -name "quality_report.tsv" \
        -exec sh -c 'cp "$1" "{output}/$(basename $(dirname "$1")).tsv"' _ {{}} \\;
        """