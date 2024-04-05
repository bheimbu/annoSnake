localrules: check_input, preprocess

rule check_input:
    output:
        touch(INPUTDIR / ".{sample}.ok")
    shell:
        """
        if [ -e {INPUTDIR}/{wildcards.sample}_R1.fastq.gz ] && [ -e {INPUTDIR}/{wildcards.sample}_R2.fastq.gz ]; then
            echo "Please make sure that interleaved reads are present in the input directory."
            exit 1
        elif [ -f {INPUTDIR}/{wildcards.sample}_R1.fastq.gz ] && [ -f {INPUTDIR}/{wildcards.sample}_R2.fastq.gz ]; then
            echo "Please make sure that interleaved reads are present in the input directory."
            exit 1
        else
            echo "We are good to go."
        fi
        """

rule megahit:
    input:
        INPUTDIR / ".{sample}.ok"
    output:
        touch(OUTDIR/ "assemblies/megahit/{sample}/.rule_completed")
    params:
        min_length=config['min_length']
    threads:
        40
    conda:
        "envs/mags.yaml"
    shell:
        """
        rm -rf {OUTDIR}/assemblies/megahit/{wildcards.sample}
        megahit --12 {INPUTDIR}/{wildcards.sample}.fastq.gz --out-prefix {wildcards.sample} --presets meta-sensitive --min-contig-len {params.min_length} -o {OUTDIR}/assemblies/megahit/{wildcards.sample} -t {threads}
        """
		
rule preprocess:
     input:
        OUTDIR/ "assemblies/megahit/{sample}/.rule_completed" 
     output:
        touch(OUTDIR/ "assemblies/preprocessed_contigs/{sample}/.rule_completed")
     shell: 
        """
        for fasta_file in {OUTDIR}/assemblies/megahit/{wildcards.sample}/{wildcards.sample}.contigs.fa; do
               mkdir -p {OUTDIR}/assemblies/preprocessed_contigs/{wildcards.sample}
               contig_num=1
               output_file={OUTDIR}/assemblies/preprocessed_contigs/{wildcards.sample}/{wildcards.sample}.fna
               table_file={OUTDIR}/assemblies/preprocessed_contigs/{wildcards.sample}/{wildcards.sample}_table.txt    
               while read -r line; do
                   if [[ $line == ">"* ]]; then
                       part_after_space="${{line#* }}"
                       new_header=">{wildcards.sample}_contig$contig_num $part_after_space"
                       echo -e "$line\t$new_header" >> "$table_file"
                       echo "$new_header" >> "$output_file"         
                       ((contig_num++))
                   else
                       echo "$line" >> "$output_file"
                   fi
               done < "$fasta_file"
        done
        """		
