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

  If you experience problems with slow download speeds for GTDB-TK, you may change the download url in the `download-db.sh` bash script that GTDB-TK uses to download the latest database. Before you can do this, a conda environment (based on *./rules/envs/gtdbtk.yaml*) has to be created by annoSnake and then you have to found 

  ..code ::

    
