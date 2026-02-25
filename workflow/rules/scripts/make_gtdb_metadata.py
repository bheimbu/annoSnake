import csv

bac = snakemake.input["bac"]
ar = snakemake.input["ar"]
outpath = snakemake.output[0]

def read_meta(path):
    with open(path) as f:
        r = csv.DictReader(f, delimiter="\t")
        for row in r:
            acc = row["accession"].strip()
            tax = row["gtdb_taxonomy"].strip()
            if acc and tax:
                yield acc, tax

with open(outpath, "w") as out:
    out.write("accession\tgtdb_taxonomy\n")
    for acc, tax in read_meta(bac):
        out.write(f"{acc}\t{tax}\n")
    for acc, tax in read_meta(ar):
        out.write(f"{acc}\t{tax}\n")
