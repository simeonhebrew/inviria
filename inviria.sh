#!/bin/bash

#Author : Simeon Hebrew


# Displaying usage arguments
usage() {
    echo "Inrivia is a lightweight pipeline for profiling the human gut virome (v0.0.1)"
    echo "Usage: $0 -R1 <forward_read> -R2 <reverse_read> -t <threads> -o <output>"
    echo "REQUIRED ARGUMENTS"
    echo "  -R1, --Read1        Forward read in fastq or fastq.gz format"
    echo "  -R2, --Read2        Reverse read in fastq or fastq.gz format"
    echo "  -t, --threads       Specify number of threads for parallel processing"
    echo "OPTIONAL ARGUMENTS"
    echo "  -o, --output        Output directory"
    echo "  -v                  Run ViromeQC for viral enchrichment scores"
    echo "PIPELINE USAGE"
    echo "  -h, --help          list all arguments"
    exit 1
}


run_viromeqc=false


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
        -v)
            
            run_viromeqc=true
            shift
            ;;
        -h|help)
	    usage
            ;;
        *)
            usage
            ;;
    esac
done

# Are all required arguments provided?
if [ -z "$R1" ] || [ -z "$R2" ] || [ -z "$THREADS" ]; then
    usage
fi

#Run viromeqc when -v is specified
if $run_viromeqc; then
    
    python3 viromeqc/viromeQC.py -i "$R1" "$R2" -o "$(basename "$R1" | sed 's/R1.*//').txt" --bowtie2_threads "$THREADS" --diamond_threads "$THREADS"
    
    
    mkdir -p vqc
    mv *.txt vqc/
    
    
    DIR="vqc"
    OUTPUT_FILE="merged_vqc.tsv"

    
    > "$OUTPUT_FILE"

    
    RF=$(find "$DIR" -type f | shuf -n 1)

    
    if [ -n "$RF" ]; then
        FIRST_LINE=$(head -n 1 "$RF")
        echo -e "$FIRST_LINE" > "$OUTPUT_FILE"
    else
        echo "No virome QC files generated"
        exit 1
    fi

    
    for FILE in "$DIR"/*; do
        if [ -f "$FILE" ]; then
            SECOND_LINE=$(sed -n '2p' "$FILE")
            echo -e "$SECOND_LINE" >> "$OUTPUT_FILE"
        fi
    done
    
    
    python3 plot_merged_file.py
fi


#Running sylph taxonomic classifier against the UHGV database
mkdir -p temporary

sylph profile votus_full.syldb -1 "$R1" -2 "$R2" -t "$THREADS" > temporary/"$(basename "$R1" | sed 's/R1.*//')_sylph.tsv"
sylph-tax taxprof temporary/*tsv -t output_three.tsv
mv *.sylphmpa temporary/
sylph-tax merge temporary/*.sylphmpa --column relative_abundance -o merged_abundance_uhgv_host.tsv

python3 sylph_uhgv_host.py

echo "Inviria finished successfully"
