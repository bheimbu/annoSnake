.. _databases::
Databases
=========

Databases are downloaded automatically. However, the user can choose to use their own protein databases, which must be saved in the correct format (see below).

.. code::

  workflow/databases/
  ├── gtdb/
  |       ├── $SAMPLE1
  │       ├── $SAMPLE2
  │       └── ...
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

If you experience problems with slow download speeds for **GTDB-TK** (see https://github.com/Ecogenomics/GTDBTk/issues/522), you may change the download url in the *download-db.sh* bash script that GTDB-TK uses to download the latest database.

.. note::

  Before you can do this, a conda environment (based on *./rules/envs/gtdbtk.yaml*) has to be created by annoSnake. Have a look at your console  

  .. code::

    [Fri Feb 23 08:30:23 2024]
    localrule setup_gtdb_tk:
       output: databases/gtdb_tk/.setup_done
       jobid: 96
       reason: Missing output files: databases/gtdb_tk/.setup_done
       resources: mem_mb=150000, disk_mb=1000, tmpdir=/tmp, partition=medium, time=1-00:00:00


             download-db.sh
        
      Activating conda environment: .snakemake/conda/470c2f2e8fcb8ca18fd3a63b874c8969

  to get the location of the *download-db.sh* file. In this example, it can be found under *annoSnake/workflow/.snakemake/conda/470c2f2e8fcb8ca18fd3a63b874c8969_/bin/download-db.sh*.

  Finally, you must change the url in the script *download-db.sh* like this (**note, you must adjust the code below to your conda environment**)

  .. code::

    cd annoSnake/workflow
    sed -i 's#DB_URL="https://data.gtdb.ecogenomic.org/releases/latest/auxillary_files/gtdbtk_data.tar.gz"#DB_URL="https://data.ace.uq.edu.au/public/gtdb/data/releases/release214/214.0/auxillary_files/gtdbtk_r214_data.tar.gz"#' .snakemake/conda/470c2f2e8fcb8ca18fd3a63b874c8969_/bin/download-db.sh 

MicrobeAnnotator
^^^^^^^^^^^^^^^^

An HTTP error may occur during MicrobeAnnotator setup. This is because the URL used to download the InterPro tables is incorrect. Again, look at your console

.. code::

  Thu Feb 22 12:00:54 2024]
  rule setup_microbeannotator:
      jobid: 99
      output: databases/microbeannotator/.setup_done
      conda-env: /scratch1/users/bheimbu/annoSnake/workflow/.snakemake/conda/   6be050a6334173be2297d22f5f22d0eb_
      shell:
        
          microbeannotator_db_builder -d databases/microbeannotator -m diamond -t 40 --light

to get the name of the conda environment, here *6be050a6334173be2297d22f5f22d0eb_*; and change the url like this (**note, you must adjust the code below to your conda environment**)

.. code::

  cd annoSnake/workflow
  sed -i 's#ftp://ftp\.ebi\.ac\.uk/pub/databases/interpro/current/release/interpro\.xml\.gz#ftp://ftp.ebi.ac.uk/pub/databases/interpro/current_release/interpro.xml.gz#' .snakemake/conda/6be050a6334173be2297d22f5f22d0eb_/lib/python3.7/site-packages/microbeannotator/database/conversion_database_creator.py


  
