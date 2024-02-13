localrules: setup_checkm, setup_pfam, setup_cazymes, setup_kegg, setup_fetchmg, setup_metaquast

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
	tar xzvf *
	checkm data setRoot .
        """
 
rule setup_pfam:
    output:
        touch("databases/pfam/.setup_done")
    retries:
        3
    shell:
        """
        cd databases/pfam
        wget -nc ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
        gunzip Pfam-A.hmm.gz
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
        tar xzvf profiles.tar.gz && rm -R profiles.tar.gz
        """

rule setup_microbeannotator:
    output:
        touch("databases/microbeannotator/.setup_done")
    conda:
        "envs/microbeannotator.yaml"
    threads:
        40
    shell:
        """
        cd databases/microbeannotator
        microbeannotator_db_builder -d . -m diamond -t {threads} --light
        """

rule setup_gtdb:
    output:
        touch("databases/gtdb/.setup_done")
    conda:
        "envs/environment.yaml"
    retries:
        3
    threads:
        40
    shell:
        """
        cd databases/gtdb
        wget -nc https://data.gtdb.ecogenomic.org/releases/release202/202.0/bac120_metadata_r202.tar.gz
        wget -nc https://data.gtdb.ecogenomic.org/releases/release202/202.0/ar122_metadata_r202.tar.gz
        tar xzvf * && rm -R *tar.gz
        awk -F '\t' '{{print $17 "\t" $1}}' bac120_metadata_r202.tsv > gtdb_vers202_metadata.csv
        awk -F '\t' '{{print $17 "\t" $1}}' ar122_metadata_r202.tsv >> gtdb_vers202_metadata.csv
        sed -i 's/;/_/g' gtdb_vers202_metadata.tsv
        git clone https://github.com/nick-youngblut/gtdb_to_taxdump.git
        wget -nc https://data.ace.uq.edu.au/public/gtdb/data/releases/release202/202.0/genomic_files_reps/gtdb_proteins_aa_reps_r202.tar.gz
        wget -nc http://ftp.tue.mpg.de/ebio/projects/struo2/GTDB_release202/taxdump/taxdump.tar.gz
        tar -xzvf taxdump.tar.gz
        python gtdb_to_taxdump/bin/gtdb_to_diamond.py -o gtdb_vers202 gtdb_proteins_aa_reps_r202.tar.gz taxdump/names.dmp taxdump/nodes.dmp
        python scripts/merge_and_truncate.py taxdump/taxID_info.csv gtdb_vers202_metadata.csv gtdb_vers202_lca.csv
        diamond makedb --in gtdb_vers202/gtdb_all.faa --db gtdb_vers202.dmnd --taxonmap gtdb_vers202/accession2taxid.tsv --taxonnodes gtdb_vers202/nodes.dmp --taxonnames gtdb_vers202/names.dmp --threads {threads}
        """
        
rule setup_fetchmg:
    output:
        touch("databases/.fetchmg_downloaded")
    conda:
        "envs/environment.yaml"
    retries:
        3
    shell:
        """
        cd databases
        git clone https://github.com/motu-tool/fetchMGs.git
        """

rule setup_metaquast:
    output:
        touch("databases/.quast_downloaded")
    conda:
        "envs/environment.yaml"
    retries:
        3
    shell:
        """
        cd databases
        git clone https://github.com/ablab/quast.git
        """
