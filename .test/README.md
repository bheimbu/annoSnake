> **Note:** this workflow currently does not support Snakemake's module
> deployment mechanism (`snakedeploy`). See the main README's
> "Known limitation" section for details and the recommended direct-clone
> usage instead.

# Test configuration

This directory provides a minimal, self-contained configuration for quickly
verifying that annoSnake runs correctly, using a small downsampled dataset
(8 samples, ~10,000 read pairs each) rather than real-scale data.

## Running the test

From the repository root:

```bash
snakemake --cores 2 --sdm conda --directory .test
```

This exercises every rule in the pipeline at least once (assembly, Prokka
annotation, blastx searches, Salmon quantification, MetaQUAST reporting)
while keeping runtime short. Functional annotation databases (PFAM, COG,
KEGG, CAZYMES) are disabled by default in `.test/config/params.yaml` to
keep the test lightweight; MAG assembly is likewise disabled.

## A note on reference databases

Some steps (e.g. `setup_gtdb*`, `setup_metaquast`) download and build
reference databases on first use. These are **not included** in this
repository and will be downloaded the first time you run the test --
this is a one-time cost, but the downloads (particularly GTDB-Tk's
reference data) can be large.

If you already have these databases built from a real (non-test) run of
annoSnake elsewhere in this repository, you can avoid re-downloading them
by symlinking `.test/databases` to your existing `databases/` directory
at the repository root:

```bash
ln -s ../databases .test/databases
```

Snakemake will then find the existing `.setup_done` marker files and skip
the corresponding setup steps entirely, so the test will run using your
already-downloaded databases rather than fetching a second, duplicate
copy.

Conversely, if you run `.test` first and want to reuse the databases it
downloads for a real analysis later, you can symlink in the other
direction from the repository root:

```bash
ln -s .test/databases databases
```

Either direction works -- the two directories are not otherwise linked
by default, so decide based on which you set up first.
