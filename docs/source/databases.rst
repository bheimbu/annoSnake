.. _databases::
Databases
=========

.. contents::
   :local:
   :backlinks: none

Install Databases 
^^^^^^^^^^^^^^^^^
.. attention::
  Before executing the full workflow, install all required databases by running

  .. code::

    snakemake --profile profile/ databases/.setup_done

In general
^^^^^^^^^^

Databases are downloaded automatically. However, you can use your own protein databases, which must be saved in the correct format (see below). The file :file:`.setup_done` in each database subdirectory is necessary to run the workflow correctly. So if you want to use your own databases, make sure that there is one in the respective subdirectories (``touch .setup_done``) 

.. code::

  workflow/databases/
  ├── cazymes/
  |       ├── dbCAN-fam-HMMs.txt.v11
  │       ├── dbCAN-fam-HMMs.txt.v11.h3f
  │       ├── dbCAN-fam-HMMs.txt.v11.h3i
  │       ├── dbCAN-fam-HMMs.txt.v11.h3m
  │       ├── dbCAN-fam-HMMs.txt.v11.h3p
  │       └── .setup_done
  ├── checkm/
  |       ├── distributions/
  │       ├── ...
  │       └── .setup_done
  ├── fetchMGs/
  |       ├── bin/
  |       ├── ...
  |       └── .setup_done
  ├── gtdb/
  |       ├── gtdb_vers202_metadata.csv
  │       ├── gtdb_vers202/
  |       ├── ...
  │       └── .setup_done
  ├── gtdb_tk/
  |       └── .setup_done
  ├── kegg/
  │       ├── ko_list
  │       ├── profiles/
  │       └── .setup_done
  ├── microbeannotator/
  |       ├── conversion.db
  |       ├── ...
  |       └── .setup_done
  ├── pfam/
  |       ├── Pfam-A.hmm
  |       ├── ...
  |       └── .setup_done
  └── quast/
        ├── metaquast.py
        ├── ...
        └── .setup_done

MicrobeAnnotator
^^^^^^^^^^^^^^^^

An HTTP error can occur during MicrobeAnnotator setup. This is because the URL used to download the InterPro tables is incorrect.

1. Run ``snakemake --profile profile/`` first to create the *microbeannotator* conda environment, then stop the workflow with :kbd:`Ctrl+D`.

2. Use ``find annoSnake/workflow/ -type f -name "conversion_database_creator.py"`` to search for :file:`conversion_database_creator.py` (here under :file:`annoSnake/workflow/.snakemake/conda/6be050a6334173be2297d22f5f22d0eb_/lib/python3.7/site-packages/microbeannotator/database/conversion_database_creator.py`).

3. Change the URL like this... (**Note, you must adjust the code below to the name of your conda environment**)

.. code::

  cd annoSnake/workflow
  sed -i 's#ftp://ftp\.ebi\.ac\.uk/pub/databases/interpro/current/release/interpro\.xml\.gz#https://ftp.ebi.ac.uk/pub/databases/interpro/current_release/interpro.xml.gz#' .snakemake/conda/6be050a6334173be2297d22f5f22d0eb_/lib/python3.7/site-packages/microbeannotator/database/conversion_database_creator.py


  
