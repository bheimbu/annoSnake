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
