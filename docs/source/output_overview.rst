.. _output::
Output
======

.. contents::
   :local:
   :backlinks: none

Tables
^^^^^^

Tables are given in **CSV** format and are ready-to-use for downstream analysis. They can be found in the :file:`{{OUTDIR}}/tables` directory.

|

.. csv-table:: **Example table:** Relative abundance of genes related to metabolic pathways.
   :header: "", "sample", "gene_name", "clr_value", "keggID", "pathway"

   "1","BEC2","ack",-0.0900557224197549,"K00925","Reductive acetogenesis"
   "2","BEC2","acsABCDE",-0.0900557224197549,"K00198","Reductive acetogenesis"
   "3","BEC2","aprAB",-0.0900557224197549,"K00394","Sulfate reduction"
   "4","BEC2","arcC",-0.0900557224197549,"K00926","Arginine Synthesis"
   "5","BEC2","argFGH",-0.0900557224197549,"K00611","Arginine Synthesis"
   "6","BEC2","dsrAB",-0.0900557224197549,"K11180","Sulfate reduction"
   "7","BEC2","fdhF",-0.0900557224197549,"K00122","Reductive acetogenesis"
   "8","BEC2","gltBD",-0.0900557224197549,"K00265","Glutamate Synthesis"
   "9","BEC2","mcrABG",-0.0900557224197549,"K00399","Methanogenesis"
   "10","BEC2","metF",-0.0900557224197549,"K00297","Reductive acetogenesis"
   "11","BEC2","narGHI",-0.0900557224197549,"K00370","Dissimilatory Nitrate Reduction"
   "12","BEC2","nirBD",-0.0900557224197549,"K00362","Dissimilatory Nitrate Reduction"
   "13","BEC2","pta",-0.0900557224197549,"K00625","Reductive acetogenesis"
   "14","BEC2","sat",-0.0900557224197549,"K00958","Sulfate reduction"
   "15","BEC2","urtABCDE",1.26078011387657,"K11959","Urea Transport"
   "16","BEC323","ack",-0.494540242875745,"K00925","Reductive acetogenesis"
   "17","BEC323","acsABCDE",0.796801709911475,"K00198","Reductive acetogenesis"
   "...","...","...",...,"...","..."

Figures
^^^^^^^

.. pdf-include:: _static/MAG_metabolic_pathways.pdf

.. raw:: html
    <iframe height="345px" width="100%" src="_static/rel_abundance_of_bacteria_and_archaea_in_metagenomes.html"></iframe>
