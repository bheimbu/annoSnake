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


.. attention::

  If you experience problems with slow download speeds for **GTDB-TK**, you may change the download url in the `download-db.sh` bash script that GTDB-TK uses to download the latest database. Before you can do this, a conda environment (based on *./rules/envs/gtdbtk.yaml*) has to be created by annoSnake. Look for following part in the DAG of jobs  

  .. code::

    [Fri Feb 23 08:30:23 2024]
    localrule setup_gtdb_tk:
       output: databases/gtdb_tk/.setup_done
       jobid: 96
       reason: Missing output files: databases/gtdb_tk/.setup_done
       resources: mem_mb=150000, disk_mb=1000, tmpdir=/tmp, partition=medium, time=1-00:00:00


             download-db.sh
        
      Activating conda environment: .snakemake/conda/470c2f2e8fcb8ca18fd3a63b874c8969

  to get the location of the *download-db.sh* file. Here, it can be found under *annoSnake/workflow/.snakemake/conda/470c2f2e8fcb8ca18fd3a63b874c8969_/bin/download-db.sh*. Note, your conda environment will have a different name than mine (*470c2f2e8fcb8ca18fd3a63b874c8969*).

  Finally, you must change following line in the script *download-db.sh* 

  .. code::

    DB_URL="https://data.gtdb.ecogenomic.org/releases/latest/auxillary_files/gtdbtk_data.tar.gz"

  to

  .. code::

    DB_URL="https://data.ace.uq.edu.au/public/gtdb/data/releases/release214/214.0/auxillary_files/gtdbtk_r214_data.tar.gz"

  Then rerun annoSnake with full download speed.    
