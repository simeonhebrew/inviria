#!/bin/bash

# Directory containing files
DIRECTORY="/store/nthukus/PAD_CONTIGS/VIROME_QC/viromeqc/OUTPUT"

# Output file to save the TSV
OUTPUT_FILE="output_qc.tsv"

# Create or clear the output file before appending
> "$OUTPUT_FILE"

# Step 1: Extract the first line from a randomly chosen file and save it to the output file
RANDOM_FILE=$(find "$DIRECTORY" -type f | shuf -n 1)

if [ -n "$RANDOM_FILE" ]; then
    # Get the first line of the random file and write it to the TSV file
    FIRST_LINE=$(head -n 1 "$RANDOM_FILE")
    echo -e "$FIRST_LINE" > "$OUTPUT_FILE"
    echo "First line from $RANDOM_FILE saved to $OUTPUT_FILE"
else
    echo "No files found in the specified directory."
    exit 1
fi

# Step 2: Extract the second line from all files and append it to the output file
echo "Extracting second lines from all files and appending to $OUTPUT_FILE..."
for FILE in "$DIRECTORY"/*; do
    if [ -f "$FILE" ]; then
        SECOND_LINE=$(sed -n '2p' "$FILE")
        echo -e "$SECOND_LINE" >> "$OUTPUT_FILE"
    fi
done

echo "Process complete. The results have been saved to $OUTPUT_FILE."
