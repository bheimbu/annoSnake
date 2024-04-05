localrules: MAG_above_threshold_bins

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
        completeness=config['completeness'],
        contamination=config['contamination'],
        metabat2=lambda w, input: Path(input["metabat2"]).parent,
        metacoag=lambda w, input: Path(input["metacoag"]).parent,
        maxbin2=lambda w, input: Path(input["maxbin2"]).parent,
        dir=lambda w, output: Path(output[0]).parent
      threads:
        20
      conda:
        "envs/mags.yaml"
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

rule MAG_above_threshold_bins:
      input:
        expand(OUTDIR/ "MAGs/bin_refinement/{sample}/.rule_completed", sample=SAMPLES)
      output:
        touch(OUTDIR/ "MAGs/above_threshold_bins/.rule_completed")
      conda:
        "envs/mags.yaml"
      shell:
        """  
        if [ ! -d {OUTDIR}/MAGs/above_threshold_bins ]; then
          mkdir -p {OUTDIR}/MAGs/above_threshold_bins
        fi
        for dir in {OUTDIR}/MAGs/bin_refinement/*/; do
          if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")
            bin_dir=$(find "$dir" -maxdepth 1 -type d -name 'metawrap_*_bins' -print -quit)
            for file in "$bin_dir"/*; do
              if [ -f "$file" ]; then
                base_name=$(basename "$file")
                new_name="$dir_name"_"$base_name"
                mkdir -p results_paired_end/MAGs/above_threshold_bins/"$dir_name"/
				cp "$file" results_paired_end/MAGs/above_threshold_bins/"$dir_name"/"$new_name"
              fi
            done
          fi
        done
        """
