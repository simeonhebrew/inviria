#!/bin/bash
# Author : Simeon Hebrew
# Inviria v0.0.1 – Human Virome Profiling Pipeline
set -e

usage() {
    echo "Inviria is a lightweight pipeline for profiling the human virome (v0.0.1)"
    echo ""
    echo "Paired-end:"
    echo "  $0 -R1 <forward.fastq.gz> -R2 <reverse.fastq.gz> -t <threads> -o <output_dir> --site-db <gut|oral|skin|vaginal>"
    echo ""
    echo "Single-end:"
    echo "  $0 -f <reads.fastq.gz> -t <threads> -o <output_dir> --site-db <gut|oral|skin|vaginal>"
    echo ""
    echo "Optional:"
    echo "  -v                     Run ViromeQC"
    echo "  --site-db              Body site database: gut (default), oral, skin, or vaginal"
    echo "  --no-filter            Write all taxonomy rows, not just contig-level"
    echo "  --min-number-kmers     Minimum number of k-mers (default: 20)"
    echo "  --min-count-correct    Minimum correct k-mer count (default: 1)"
    echo "  --min-spacing          Minimum k-mer spacing (default: 10)"
    echo "  -h                     Show this help"
    exit 1
}

run_viromeqc=false
SITE_DB="gut"
NO_FILTER=""
MIN_NUMBER_KMERS=20
MIN_COUNT_CORRECT=1
MIN_SPACING=10


# Parse arguments

while [[ $# -gt 0 ]]; do
    case "$1" in
        -R1)                 R1="$2";                 shift 2 ;;
        -R2)                 R2="$2";                 shift 2 ;;
        -f|--file)           FILE="$2";               shift 2 ;;
        -t|--threads)        THREADS="$2";            shift 2 ;;
        -o|--output)         OUTPUT="$2";             shift 2 ;;
        --site-db)           SITE_DB="$2";            shift 2 ;;
        --no-filter)         NO_FILTER="--no-filter"; shift ;;
        --min-number-kmers)  MIN_NUMBER_KMERS="$2";   shift 2 ;;
        --min-count-correct) MIN_COUNT_CORRECT="$2";  shift 2 ;;
        --min-spacing)       MIN_SPACING="$2";        shift 2 ;;
        -v)                  run_viromeqc=true;       shift ;;
        -h|--help)           usage ;;
        *)                   usage ;;
    esac
done


# Validating that the required arguments are present

if [ -z "$THREADS" ] || [ -z "$OUTPUT" ]; then
    usage
fi

if { [ -z "$R1" ] || [ -z "$R2" ]; } && [ -z "$FILE" ]; then
    usage
fi


# Resolve paths to the database and corresponding taxonomy files

case "$SITE_DB" in
    gut)
        SYLPH_DB="../databases/inviria_exp_gut_final_mq_hq_c_100.syldb"
        TAXONOMY_FILE="../taxonomy/inviria_gut_taxonomy_file_updated.tsv"
        ;;
    oral)
        SYLPH_DB="../databases/HOVD-geneseqences_100.syldb"
        TAXONOMY_FILE="../taxonomy/hovd_taxonomy_file.tsv"
        ;;
    skin)
        SYLPH_DB="../databases/skin_virus_rep_100.syldb"
        TAXONOMY_FILE="../taxonomy/svd_taxonomy_file.tsv"
        ;;
    vaginal)
        SYLPH_DB="../databases/VMGC_virus_vOTU_100.syldb"
        TAXONOMY_FILE="../taxonomy/vmgc_taxonomy_file.tsv"
        ;;
    *)
        echo "Error: Unknown --site-db value '${SITE_DB}'. Choose from: gut, oral, skin, vaginal."
        exit 1
        ;;
esac

echo "Using body-site database : ${SITE_DB} (${SYLPH_DB})"
echo "Using taxonomy file      : ${TAXONOMY_FILE}"
echo "Sylph parameters         : --min-number-kmers ${MIN_NUMBER_KMERS} --min-count-correct ${MIN_COUNT_CORRECT} --min-spacing ${MIN_SPACING}"

mkdir -p "$OUTPUT"/{temporary,vqc}


# Extracting out the sample name

if [ -n "$FILE" ]; then
    SAMPLE=$(basename "$FILE")
    SAMPLE="${SAMPLE%%.*}"
else
    SAMPLE=$(basename "$R1")
    SAMPLE=$(echo "$SAMPLE" | sed 's/_1.*//')
fi


# Perform ViromeQC is argument is selected (optional)

if $run_viromeqc; then
    echo "========================================="
    echo " Step 1: ViromeQC"
    echo "========================================="
    if [ -n "$FILE" ]; then
        python3 viromeqc/viromeQC.py \
            -i "$FILE" \
            -o "${SAMPLE}.txt" \
            --bowtie2_threads "$THREADS" \
            --diamond_threads "$THREADS"
    else
        python3 viromeqc/viromeQC.py \
            -i "$R1" "$R2" \
            -o "${SAMPLE}.txt" \
            --bowtie2_threads "$THREADS" \
            --diamond_threads "$THREADS"
    fi

    mv *.txt "$OUTPUT/vqc/"
    OUTPUT_FILE="$OUTPUT/vqc/viromeqc_results.tsv"
    > "$OUTPUT_FILE"
    FIRST_FILE=$(find "$OUTPUT/vqc" -type f -name "*.txt" | head -n 1)
    if [ -n "$FIRST_FILE" ]; then
        head -n 1 "$FIRST_FILE" > "$OUTPUT_FILE"
        for f in "$OUTPUT"/vqc/*.txt; do
            sed -n '2p' "$f" >> "$OUTPUT_FILE"
        done
    else
        echo "No ViromeQC output generated"
        exit 1
    fi
    #python3 plot_merged_file.py
fi


# Perform viral profiling using sylph

echo "========================================="
echo " Step 2: Sylph Profiling"
echo "========================================="
if [ -n "$FILE" ]; then
    # Single-end
    sylph profile \
        -c 100 \
        -u \
        --min-number-kmers "$MIN_NUMBER_KMERS" \
        --min-count-correct "$MIN_COUNT_CORRECT" \
        --min-spacing "$MIN_SPACING" \
        "$SYLPH_DB" \
        "$FILE" \
        -t "$THREADS" \
        > "$OUTPUT/temporary/${SAMPLE}_sylph.tsv"
else
    # Paired-end
    sylph profile \
        -c 100 \
        -u \
        --min-number-kmers "$MIN_NUMBER_KMERS" \
        --min-count-correct "$MIN_COUNT_CORRECT" \
        --min-spacing "$MIN_SPACING" \
        "$SYLPH_DB" \
        -1 "$R1" \
        -2 "$R2" \
        -t "$THREADS" \
        > "$OUTPUT/temporary/${SAMPLE}_sylph.tsv"
fi


# Using sylph-tax for taxonomic processing

echo "========================================="
echo " Step 3: Sylph-tax Profiling"
echo "========================================="
sylph-tax taxprof \
    "$OUTPUT"/temporary/*_sylph.tsv \
    -t "$TAXONOMY_FILE"

mv *.sylphmpa "$OUTPUT/temporary/"

echo "Merging abundance tables..."
sylph-tax merge \
    "$OUTPUT"/temporary/*.sylphmpa \
    --column relative_abundance \
    -o "$OUTPUT/merged_abundance_${SITE_DB}_virome.tsv"


# Step 4: Parsing the taxonomic table for sample x vOTU table construction

echo "========================================="
echo " Step 4: Parsing Taxonomy Table"
echo "========================================="
python3 parse_taxonomy_v3.py \
    -i "$OUTPUT/merged_abundance_${SITE_DB}_virome.tsv" \
    -o "$OUTPUT/output_abund_${SITE_DB}_inviria.tsv" \
    $NO_FILTER


echo "========================================="
echo " Inviria finished successfully."
echo " Results in        : $OUTPUT"
echo " Final table       : $OUTPUT/output_abund_${SITE_DB}_inviria.tsv"
echo "========================================="
