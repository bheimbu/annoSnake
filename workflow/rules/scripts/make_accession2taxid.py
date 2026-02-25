import csv
import sys
import re

faa = snakemake.input["faa"]
genome_taxid_tsv = snakemake.input["genome_taxid"]
out_tsv = snakemake.output[0]

def norm_acc(acc: str) -> str:
    acc = acc.strip()
    acc = re.sub(r"^(RS_|GB_|NZ_)", "", acc)  # NZ_ is optional but common
    acc = acc.replace("GCA_", "GCA").replace("GCF_", "GCF")
    return acc

# Extract the genome accession (GCA/GCF + digits + .version) from a seq_id
GENOME_RE = re.compile(r"(GCA|GCF)_?\d+\.\d+")

def extract_genome_accession(seq_id: str) -> str | None:
    seq_id = re.sub(r"^(RS_|GB_|NZ_)", "", seq_id)
    m = GENOME_RE.search(seq_id)
    if not m:
        return None
    return norm_acc(m.group(0))

# load genome -> taxid mapping
genome2taxid = {}
with open(genome_taxid_tsv) as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        genome2taxid[norm_acc(row["accession"])] = row["taxid"]

total = 0
missing = 0
no_genome = 0

with open(out_tsv, "w") as out:
    out.write("accession\taccession.version\ttaxid\tgi\n")

    with open(faa) as f:
        for line in f:
            if not line.startswith(">"):
                continue
            total += 1
            header = line[1:].strip()
            seq_id = header.split()[0]

            genome = extract_genome_accession(seq_id)
            if genome is None:
                no_genome += 1
                continue

            taxid = genome2taxid.get(genome)
            if taxid is None:
                missing += 1
                continue

            out.write(f"{seq_id}\t{genome}\t{taxid}\t\n")

print(
    f"# headers={total}, mapped={total-missing-no_genome}, "
    f"missing_taxid={missing}, no_genome_found={no_genome}",
    file=sys.stderr
)
