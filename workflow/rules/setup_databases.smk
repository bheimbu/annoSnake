localrules: setup_gtdb_tk, setup_checkm2, setup_pfam, setup_cazymes, setup_kegg, setup_fetchmg, setup_metaquast, setup_gtdb1, setup_gtdb2, setup_gtdb4

rule setup_databases:
    input:
        "databases/checkm/.setup_done",
        "databases/gtdb_tk/.setup_done",
        "databases/pfam/.setup_done",
        "databases/cazymes/.setup_done",
        "databases/kegg/.setup_done",
        "databases/microbeannotator/.setup_done",
        "databases/gtdb/.setup_done",
        "databases/fetchMGs/.setup_done",
        "databases/quast/.setup_done",
    output:
        touch("databases/.setup_done")

rule setup_checkm2:
    output:
        touch("databases/checkm2/.setup_done")
    conda:
        "envs/checkm2.yaml"
    retries:
        3
    shell:
        """
		checkm2 database --download --path databases/checkm2
        """

rule setup_gtdb_tk:
    output:
        touch("databases/gtdb_tk/.setup_done")
    conda:
        "envs/gtdbtk.yaml"
    retries:
        3
    shell:
        """
        download-db.sh
        """

rule setup_pfam:
    output:
        touch("databases/pfam/.setup_done")
    conda:
        "envs/environment.yaml"
    retries:
        3
    shell:
        """
        cd databases/pfam
        wget -nc ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
        wget -nc https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.dat.gz
        gunzip *gz
        hmmpress Pfam-A.hmm
        """

rule setup_cazymes:
    output:
        touch("databases/cazymes/.setup_done")
    conda:
        "envs/environment.yaml"
    retries:
        3
    shell:
        """
        cd databases/cazymes
        wget -nc http://dbcan-hcc.unl.edu/download/Databases/dbCAN-old@UGA/dbCAN-fam-HMMs.txt
        hmmpress dbCAN-fam-HMMs.txt
        """

rule setup_kegg:
    output:
        touch("databases/kegg/.setup_done")
    retries:
        3
    shell:
        """
        cd databases/kegg
        wget -nc ftp://ftp.genome.jp/pub/db/kofam/ko_list.gz
        wget -nc ftp://ftp.genome.jp/pub/db/kofam/profiles.tar.gz
        gunzip ko_list.gz
        tar -xzf profiles.tar.gz && rm -R profiles.tar.gz
        """

rule setup_microbeannotator:
    output:
        touch("databases/microbeannotator/.setup_done")
    conda:
        "envs/microbeannotator.yaml"
    params:
        db=lambda wildcards, output: Path(output[0]).parent
    threads:
        40
    shell:
        """
		find . -type f -name "conversion_database_creator.py" -exec sed -i 's|ftp://ftp.ebi.ac.uk|https://ftp.ebi.ac.uk|g' {{}} +
        microbeannotator_db_builder -d {params.db} -m diamond -t {threads} --light
        """

rule setup_gtdb1:
    output:
        "databases/gtdb/gtdb-taxdump-latest/taxid.map"
    params:
        tarball="https://data.gtdb.aau.ecogenomic.org/releases/latest/genomic_files_reps/gtdb_proteins_aa_reps.tar.gz",
        bac="https://data.gtdb.aau.ecogenomic.org/releases/latest/bac120_taxonomy.tsv.gz",
        ar="https://data.gtdb.aau.ecogenomic.org/releases/latest/ar53_taxonomy.tsv.gz",
        bac_meta="https://data.gtdb.aau.ecogenomic.org/releases/latest/bac120_metadata.tsv.gz",
        ar_meta="https://data.gtdb.aau.ecogenomic.org/releases/latest/ar53_metadata.tsv.gz"
    conda:
        "envs/taxonkit.yaml"
    retries:
        3
    shell:
        """      
        cd databases/gtdb
        wget -nc {params.tarball}
        wget -nc {params.bac}
        wget -nc {params.ar}
        wget -nc {params.bac_meta}
        wget -nc {params.ar_meta}
        gunzip *_metadata.tsv.gz
        
        taxonkit create-taxdump --gtdb ar53_taxonomy.tsv.gz bac120_taxonomy.tsv.gz --out-dir gtdb-taxdump-latest        
        """

rule setup_gtdb2:
    input:
        taxid_map="databases/gtdb/gtdb-taxdump-latest/taxid.map",
    output:
        acc2tax="databases/gtdb/gtdb_latest/accession2taxid.tsv",
        names_out="databases/gtdb/gtdb_latest/names.dmp",
        nodes_out="databases/gtdb/gtdb_latest/nodes.dmp"
    params:
        tmpdir="databases/gtdb/temp_faa",
        tarball="databases/gtdb/gtdb_proteins_aa_reps.tar.gz",
        names="databases/gtdb/gtdb-taxdump-latest/names.dmp",
        nodes="databases/gtdb/gtdb-taxdump-latest/nodes.dmp"
    conda:
        "envs/gtdb_to_taxdump.yaml"
    script:
        "scripts/gtdb_to_diamond_taxonkit.py"

rule setup_gtdb3:
    input:
        acc2tax="databases/gtdb/gtdb_latest/accession2taxid.tsv"
    output:
        faa="databases/gtdb/gtdb_latest/gtdb_all.faa.gz"
    params:
        tmpdir="databases/gtdb/temp_faa"
    conda:
        "envs/gtdb_to_taxdump.yaml"
    threads: 40
    shell:
        """
        echo "Merging FAA files (this takes ~10-30 minutes)..."
        cd {params.tmpdir}
        
        # Fast merge using GNU Parallel (Tange, O. (2024, December 22). GNU Parallel 20241222 ('Bashar'))
        find . -name "*_protein.faa.gz" | sort | \
          parallel -j {threads} --keep-order 'zcat {{}}' | \
          pigz -p {threads} > ../gtdb_latest/gtdb_all.faa.gz
        
        echo "Merge complete! Cleaning up temp files..."
        cd ..
        rm -rf temp_faa
        """
        
rule setup_gtdb4:
    input:
        names_dmp="databases/gtdb/gtdb-taxdump-latest/names.dmp"
    output:
        "databases/gtdb/gtdb_latest_lca.csv"
    params:
        bac_metadata="databases/gtdb/bac120_metadata.tsv",
        ar_metadata="databases/gtdb/ar53_metadata.tsv"
    conda:
        "envs/gtdb_to_taxdump.yaml"
    script:
        "scripts/merge_and_truncate_latest.py"

rule setup_gtdb5:
    input:
        "databases/gtdb/gtdb_latest_lca.csv",
        "databases/gtdb/gtdb_latest/gtdb_all.faa.gz"
    output:
        touch("databases/gtdb/.setup_done")
    params:
        gtdb=lambda w, input: Path(input[0]).parent,
        dmnd=lambda w, input: Path(input[1]).parent
    conda:
        "envs/environment.yaml"
    threads:
        40
    shell:
        """
        diamond makedb --in {input[1]} --db {params.gtdb}/gtdb_latest.dmnd --taxonmap {params.dmnd}/accession2taxid.tsv --taxonnodes {params.dmnd}/nodes.dmp --taxonnames {params.dmnd}/names.dmp --threads {threads} --quiet
        rm -rf {params.gtdb}/*gz
        """
       
rule setup_fetchmg:
    output:
        touch("databases/fetchMGs/.setup_done")
    conda:
        "envs/fetchmg.yaml"
    retries:
        3
    shell:
        """
        git clone https://github.com/motu-tool/fetchMGs.git databases/fetchMGs
        """

rule setup_metaquast:
    output:
        touch("databases/quast/.setup_done")
    conda:
        "envs/environment.yaml"
    retries:
        3
    shell:
        """
        git clone https://github.com/ablab/quast.git databases/quast
        """
