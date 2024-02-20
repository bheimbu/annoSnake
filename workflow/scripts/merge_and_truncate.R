  # Read the first input file with headers
  df1 <- read.table(snakemake@input[[0]], sep = "\t", header = TRUE)

  # Read the second input file without headers
  lines <- readLines(snakemake@params[['taxdump']])

  # Create an empty list to store the lines of the output, including the header
  output_lines <- c("taxID,name,rank,lca")

  # Iterate through the rows of the first input file with tqdm progress bar
  for (i in 1:nrow(df1)) {
    row <- df1[i,]
    name_to_match <- row[['name']]
    rank <- row[['rank']]

    # Search for a matching line in the second input file
    matching_line <- NULL
    for (line in lines) {
      if (grepl(name_to_match, line)) {
        matching_line <- line
        break
      }
    }

    if (!is.null(matching_line)) {
      # Truncate the matching line based on the rank
      if (rank == 'superkingdom') {
        matching_line <- unlist(strsplit(matching_line, "_p__"))[1]
      } else if (rank == 'phylum') {
        matching_line <- unlist(strsplit(matching_line, "_c__"))[1]
      } else if (rank == 'class') {
        matching_line <- unlist(strsplit(matching_line, "_o__"))[1]
      } else if (rank == 'order') {
        matching_line <- unlist(strsplit(matching_line, "_f__"))[1]
      } else if (rank == 'family') {
        matching_line <- unlist(strsplit(matching_line, "_g__"))[1]
      } else if (rank == 'genus') {
        matching_line <- unlist(strsplit(matching_line, "_s__"))[1]
      } else if (rank %in% c('species', 'subspecies')) {
        # For species and subspecies, remove the accession number
        matching_line <- unlist(strsplit(matching_line, ","))[1]
      }

      # Combine the original row with the matching line
      combined_line <- paste(row[['taxID']], row[['name']], row[['rank']], matching_line, sep = ",")
      output_lines <- c(output_lines, combined_line)
    }
  }

  # Write the output lines to the output file
  writeLines(output_lines, con = snakemake@output[['lca']])
