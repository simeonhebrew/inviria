#!/bin/bash

# Function to display usage/help message
usage() {
    echo "Usage: $0 -R1 <forward_read> -R2 <reverse_read> -t <threads> -o <output>"
    echo "  -R1, --Read1        Forward read in fastq or fastq.gz format"
    echo "  -R2, --Read2        Reverse read in fastq or fastq.gz format"
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -R1|--R1)
            R1="$2"
            shift 2
            ;;
        -R2|--R2)
            R2="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -o|--OUTPUT)
            OUTPUT="$2"
            shift 2
            ;;
	*)
            usage
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$R1" ] || [ -z "$R2" ] || [ -z "$THREADS" ]; then
    usage
fi


python3 viromeqc/viromeQC.py -i $R1 $R2 -o "$(basename $R1 .fastq).txt" --bowtie2_threads 32 --diamond_threads 32

mkdir -p vqc

mv *txt vqc/


DIR="vqc"
OUTPUT_FILE="merged_vqc.tsv"

> "merged_vqc.tsv"

RF=$(find "$DIR" -type f | shuf -n 1)

if [ -n "$RF" ]; then
    FIRST_LINE=$(head -n 1 "$RF")
    echo -e "$FIRST_LINE" > "$OUTPUT_FILE"
else
    echo "No virome qc files generated"
    exit 1
fi

for FILE in "$DIR"/*; do
    if [ -f "$FILE" ]; then
        SECOND_LINE=$(sed -n '2p' "$FILE")
        echo -e "$SECOND_LINE" >> "$OUTPUT_FILE"
    fi
done


python3 plot_merged_file.py

mkdir -p temporary

sylph profile imgvr_c200_v0.3.0.syldb -1 $R1 -2 $R2 -t 32 > temporary/"$(basename $R1 .fastq)_sylph.tsv"
sylph-tax taxprof temporary/*tsv -t IMGVR_4.1
mv *.sylphmpa temporary/
sylph-tax merge temporary/*.sylphmpa --column relative_abundance -o merged_abundance.tsv

python3 sylphylo.py

echo "inviria finished successfully, output files present in otu_tax table directory"
