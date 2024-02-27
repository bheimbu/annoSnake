.. _databases::
Databases
=========

Databases are downloaded automatically. However, the user can choose to use their own protein databases, which must be saved in the correct format (see below). The empty file *.setup_done* in each database subdirectory is important in order to run the workflow correctly. So if you want to use your own databases, make sure you create one (``touch .setup_done``) 

.. code::

  workflow/databases/
  ├── cazymes/
  |       ├── dbCAN-fam-HMMs.txt.v11
  │       ├── dbCAN-fam-HMMs.txt.v11.h3f
  │       ├── dbCAN-fam-HMMs.txt.v11.h3i
  │       ├── dbCAN-fam-HMMs.txt.v11.h3m
  │       ├── dbCAN-fam-HMMs.txt.v11.h3p
  │       └── .setup_done
  ├── kegg/
  |       ├── $SAMPLE1
  │       ├── $SAMPLE2
  │       └── ...
  ├── microbeannotator/
  |       ├── $SAMPLE1
  |       ├── $SAMPLE2
  |       └── ...
  ├── gtdbtk/
  |       ├── $SAMPLE1
  │       ├── $SAMPLE2
  │       └── ...
  ├── fetchMGs/
  |       ├── $SAMPLE1
  |       ├── $SAMPLE2
  |       └── ...
  ├── checkm/
  │       ├── $SAMPLE1
  │       ├── $SAMPLE2
  │       └── ...
  ├── cazymes/
  |       ├── $SAMPLE1
  |       ├── $SAMPLE2
  |       └── ...
  └── quast/
        ├── $SAMPLE1
        ├── $SAMPLE2
        └── ...


GTDB-TK
^^^^^^^

Sometimes, the download speed of the **GTDB-TK** database decreases dramatically (see https://github.com/Ecogenomics/GTDBTk/issues/522). If this is the case for you too, you can change the download URL in the bash script *download-db.sh* as follows.

1. The *gtdbtk* conda environment (based on *./rules/envs/gtdbtk.yaml*) has to be created first by annoSnake.

2. Then, have a look at your console...  

.. code::

    [Fri Feb 23 08:30:23 2024]
    localrule setup_gtdb_tk:
       output: databases/gtdb_tk/.setup_done
       jobid: 96
       reason: Missing output files: databases/gtdb_tk/.setup_done
       resources: mem_mb=150000, disk_mb=1000, tmpdir=/tmp, partition=medium, time=1-00:00:00


             download-db.sh
        
      Activating conda environment: .snakemake/conda/470c2f2e8fcb8ca18fd3a63b874c8969

In this example, *download-db.sh* can be found under *annoSnake/workflow/.snakemake/conda/470c2f2e8fcb8ca18fd3a63b874c8969_/bin/download-db.sh*.

3. You must change the URL in the script *download-db.sh* like this (**note, you must adjust the code below to the name of your conda environment**)

.. code::

  cd annoSnake/workflow
  sed -i 's#DB_URL="https://data.gtdb.ecogenomic.org/releases/latest/auxillary_files/gtdbtk_data.tar.gz"#DB_URL="https://data.ace.uq.edu.au/public/gtdb/data/releases/release214/214.0/auxillary_files/gtdbtk_r214_data.tar.gz"#' .snakemake/conda/470c2f2e8fcb8ca18fd3a63b874c8969_/bin/download-db.sh 

MicrobeAnnotator
^^^^^^^^^^^^^^^^

An HTTP error may occur during MicrobeAnnotator setup. This is because the URL used to download the InterPro tables is incorrect. Again, look at your console...

.. code::

  Thu Feb 22 12:00:54 2024]
  rule setup_microbeannotator:
      jobid: 99
      output: databases/microbeannotator/.setup_done
      conda-env: /scratch1/users/bheimbu/annoSnake/workflow/.snakemake/conda/   6be050a6334173be2297d22f5f22d0eb_
      shell:
        
          microbeannotator_db_builder -d databases/microbeannotator -m diamond -t 40 --light

to get the name of the conda environment, here *6be050a6334173be2297d22f5f22d0eb_*; and change the URL like this (**note, you must adjust the code below to the name of your conda environment**)

.. code::

  cd annoSnake/workflow
  sed -i 's#ftp://ftp\.ebi\.ac\.uk/pub/databases/interpro/current/release/interpro\.xml\.gz#https://ftp.ebi.ac.uk/pub/databases/interpro/current_release/interpro.xml.gz#' .snakemake/conda/6be050a6334173be2297d22f5f22d0eb_/lib/python3.7/site-packages/microbeannotator/database/conversion_database_creator.py


  
