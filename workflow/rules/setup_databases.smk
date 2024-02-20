localrules: setup_gtdb_tk, setup_checkm, setup_pfam, setup_cazymes, setup_kegg, setup_gtdb1, setup_gtdb2, setup_fetchmg, setup_metaquast

rule setup_checkm:
    output:
        touch("databases/checkm/.setup_done")
    conda:
        "envs/MAGs.yaml"
    retries:
        3
    shell:
        """
	cd databases/checkm
        wget -nc https://zenodo.org/records/7401545/files/checkm_data_2015_01_16.tar.gz?download=1
	tar xzf *
	checkm data setRoot .
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
        wget -nc https://bcb.unl.edu/dbCAN2/download/Databases/dbCAN-old@UGA/dbCAN-fam-HMMs.txt.v11
        hmmpress dbCAN-fam-HMMs.txt.v11
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
        microbeannotator_db_builder -d {params.db} -m diamond -t {threads} --light
        """

rule setup_gtdb1:
    output:
        "databases/gtdb/gtdb_vers202_metadata.csv"
    conda:
        "envs/gtdb_to_taxdump.yaml"
    retries:
        3
    shell:
        """
        cd databases/gtdb
        wget -nc http://ftp.tue.mpg.de/ebio/projects/struo2/GTDB_release202/taxdump/taxdump.tar.gz
        tar -xzf taxdump.tar.gz
        wget -nc https://data.gtdb.ecogenomic.org/releases/release202/202.0/bac120_metadata_r202.tar.gz
        wget -nc https://data.gtdb.ecogenomic.org/releases/release202/202.0/ar122_metadata_r202.tar.gz
        tar -xzf bac120_metadata_r202.tar.gz
        tar -xzf ar122_metadata_r202.tar.gz
        awk -F '\t' '{{print $17 "\t" $1}}' bac120_metadata_r202.tsv > gtdb_vers202_metadata.csv
        awk -F '\t' '{{print $17 "\t" $1}}' ar122_metadata_r202.tsv >> gtdb_vers202_metadata.csv
        sed -i -e 's/;/_/g' -e 's/\t/,/g' gtdb_vers202_metadata.csv
        wget -nc https://data.ace.uq.edu.au/public/gtdb/data/releases/release202/202.0/genomic_files_reps/gtdb_proteins_aa_reps_r202.tar.gz
        gtdb_to_diamond.py -o gtdb_vers202 gtdb_proteins_aa_reps_r202.tar.gz taxdump/names.dmp taxdump/nodes.dmp
        """

rule setup_gtdb2:
    input:
        "databases/gtdb/gtdb_vers202_metadata.csv"
    output:
        lca="databases/gtdb/gtdb_vers202_lca.csv"
    params:
        taxdump="databases/gtdb/taxdump/taxID_info.tsv",
        meta=lambda w, input: Path(input[0]).parent
    conda:
        "envs/gtdb_to_taxdump.yaml"
    script:
        "scripts/merge_and_truncate.R"

rule setup_gtdb3:
    input:
        "databases/gtdb/gtdb_vers202_lca.csv"
    output:
        touch("databases/gtdb/.setup_done")
    params:
        gtdb=lambda w, input: Path(input[0]).parent,
        dmnd=lambda w, output: Path(output[0]).parent,
        faa="databases/gtdb/gtdb_vers202/gtdb_all.faa"
    conda:
        "envs/environment.yaml"
    threads:
        40
    shell:
        """
        diamond makedb --in {input} --db {params.dmnd}/gtdb_vers202.dmnd --taxonmap {params.gtdb}/accession2taxid.tsv --taxonnodes {params.gtdb}/nodes.dmp --taxonnames {params.gtdb}/names.dmp --threads {threads}
        rm -rf {params.dmnd}/*gz
        """
        
rule setup_fetchmg:
    output:
        touch("databases/fetchMGs/.setup_done")
    conda:
        "envs/environment.yaml"
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
