import argparse
import pandas as pd

def merge_and_truncate(input_file1, input_file2, output_file):
    # Read the first input file with headers
    df1 = pd.read_csv(input_file1)

    # Read the second input file without headers
    with open(input_file2, 'r') as file:
        lines = file.readlines()

    # Create an empty list to store the lines of the output, including the header
    output_lines = []

    # Add a header line to the output
    output_lines.append("taxID,name,rank,lca")

    # Iterate through the rows of the first input file
    for _, row in df1.iterrows():
        name_to_match = row['name']
        rank = row['rank']
        
        # Search for a matching line in the second input file
        matching_line = None
        for line in lines:
            if name_to_match in line:
                matching_line = line.strip()
                break

        if matching_line is not None:
            # Truncate the matching line based on the rank
            if rank == 'superkingdom':
                matching_line = matching_line.split('_p__')[0]
            elif rank == 'phylum':
                matching_line = matching_line.split('_c__')[0]
            elif rank == 'class':
                matching_line = matching_line.split('_o__')[0]
            elif rank == 'order':
                matching_line = matching_line.split('_f__')[0]
            elif rank == 'family':
                matching_line = matching_line.split('_g__')[0]
            elif rank == 'genus':
                matching_line = matching_line.split('_s__')[0]
            elif rank in ['species', 'subspecies']:
            # For species and subspecies, remove the accession number
                matching_line = matching_line.split(',')[0]

           # Combine the original row with the matching line
            combined_line = f"{row['taxID']},{row['name']},{row['rank']},{matching_line}"
            output_lines.append(combined_line)

    # Write the output lines to the output file
    with open(output_file, 'w') as file:
        file.write('\n'.join(output_lines))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Merge and truncate taxonomic data")
    parser.add_argument("input1", help="First input CSV file with headers")
    parser.add_argument("input2", help="Second input CSV file without headers")
    parser.add_argument("output", help="Output CSV file")
    args = parser.parse_args()

    merge_and_truncate(args.input1, args.input2, args.output)

