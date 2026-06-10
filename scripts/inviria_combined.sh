#!/bin/bash
# Author : Simeon Hebrew
# Inviria v0.0.1 – Human Virome Profiling Pipeline
set -euo pipefail


# Usage

usage() {
    echo "Inviria is a lightweight pipeline for profiling the human virome (v0.0.1)"
    echo ""
    echo "STEP 1 – Build the clustered sylph database (run once per project):"
    echo "  $0 build-db --contigs <contigs.fasta> --site-db <gut|oral|skin|vaginal> -o <output_dir> [-t <threads>]"
    echo ""
    echo "STEP 2 – Profile samples against the pre-built database:"
    echo "  Paired-end:"
    echo "    $0 profile -R1 <fwd.fastq.gz> -R2 <rev.fastq.gz> --sylph-db <path/to/db.syldb> -o <output_dir> [-t <threads>] [-v]"
    echo ""
    echo "  Single-end:"
    echo "    $0 profile -f <reads.fastq.gz> --sylph-db <path/to/db.syldb> -o <output_dir> [-t <threads>] [-v]"
    echo ""
    echo "build-db options:"
    echo "  --contigs    User-supplied putative virus contigs FASTA (required)"
    echo "  --site-db    Body site reference: gut (default), oral, skin, or vaginal"
    echo "  -o           Output directory (the .syldb path will be printed on completion)"
    echo "  -t           Threads (default: 4)"
    echo ""
    echo "profile options:"
    echo "  -f / -R1 -R2  Input reads (single- or paired-end)"
    echo "  --sylph-db    Path to the .syldb built by build-db (required)"
    echo "  -o            Output directory"
    echo "  -t            Threads (default: 4)"
    echo "  -v            Also run ViromeQC"
    echo "  --no-filter   Write all taxonomy rows, not just contig-level"
    exit 1
}


# Subcommand dispatch

if [[ $# -lt 1 ]]; then usage; fi
SUBCOMMAND="$1"; shift

case "$SUBCOMMAND" in
    build-db) ;;
    profile)  ;;
    -h|--help) usage ;;
    *) echo "ERROR: Unknown subcommand '$SUBCOMMAND'. Expected 'build-db' or 'profile'."; usage ;;
esac


# Defaults

SITE_DB="gut"
CONTIGS=""
OUTPUT=""
THREADS=4
R1=""
R2=""
FILE=""
SYLPH_DB_INPUT=""
run_viromeqc=false
NO_FILTER=""


# Parse arguments
#
while [[ $# -gt 0 ]]; do
    case "$1" in
        -R1)           R1="$2";              shift 2 ;;
        -R2)           R2="$2";              shift 2 ;;
        -f|--file)     FILE="$2";            shift 2 ;;
        -t|--threads)  THREADS="$2";         shift 2 ;;
        -o|--output)   OUTPUT="$2";          shift 2 ;;
        --contigs)     CONTIGS="$2";         shift 2 ;;
        --site-db)     SITE_DB="$2";         shift 2 ;;
        --sylph-db)    SYLPH_DB_INPUT="$2";  shift 2 ;;
        --no-filter)   NO_FILTER="--no-filter"; shift ;;
        -v)            run_viromeqc=true;    shift ;;
        -h|--help)     usage ;;
        *) echo "ERROR: Unknown option: $1"; usage ;;
    esac
done


# Shared validation

if [[ -z "$OUTPUT" ]]; then
    echo "ERROR: Output directory (-o) is required."
    usage
fi
mkdir -p "$OUTPUT"


#  build-db subcommand

if [[ "$SUBCOMMAND" == "build-db" ]]; then

    if [[ -z "$CONTIGS" ]]; then
        echo "ERROR: --contigs is required for build-db."
        usage
    fi

    # Select site reference FASTA
    case "$SITE_DB" in
        gut)     SITE_DB_FASTA="../databases/inviria_exp_gut_final_mq_hq_c.fasta" ;;
        oral)    SITE_DB_FASTA="../databases/HOVD-geneseqences.fasta" ;;
        skin)    SITE_DB_FASTA="../databases/skin_virus_rep.fa" ;;
        vaginal) SITE_DB_FASTA="../databases/VMGC_virus_vOTU.fa" ;;
        *)
            echo "ERROR: Unknown --site-db '$SITE_DB'. Choose from: gut, oral, skin, vaginal."
            exit 1 ;;
    esac

    if [[ ! -f "$SITE_DB_FASTA" ]]; then
        echo "ERROR: Site database FASTA not found: $SITE_DB_FASTA"
        exit 1
    fi

    # Output paths (all under $OUTPUT/db/)
    DB_DIR="$OUTPUT/db"
    mkdir -p "$DB_DIR"

    HYBRID_FASTA="$DB_DIR/inviria_hybrid_${SITE_DB}.fasta"
    FLTR="$DB_DIR/fltr_all.txt"
    ANI_TSV="$DB_DIR/ani_all.tsv"
    ANI_IDS="$DB_DIR/ani_all.ids.tsv"
    CLUSTERS_TSV="$DB_DIR/clusters_all.tsv"
    CLUSTERS_LIST="$DB_DIR/clusters_list.txt"
    CLUSTERS_FASTA="$DB_DIR/inviria_hybrid_${SITE_DB}_clusters.fasta"
    SYLPH_DB="$DB_DIR/inviria_hybrid_${SITE_DB}_clusters.syldb"

    echo "==> [build-db] Site DB : $SITE_DB ($SITE_DB_FASTA)"
    echo "==> [build-db] Contigs  : $CONTIGS"
    echo "==> [build-db] Output   : $DB_DIR"
    echo ""

    # Step 1: Merge
    echo "==> [1/5] Merging site database with user contigs..."
    cat "$SITE_DB_FASTA" "$CONTIGS" > "$HYBRID_FASTA"

    # Step 2: vclust prefilter
    echo "==> [2/5] vclust prefilter..."
    vclust prefilter \
        -i "$HYBRID_FASTA" \
        -o "$FLTR" \
        --min-ident 0.95

    # Step 3: vclust align
    echo "==> [3/5] vclust align..."
    vclust align \
        -i "$HYBRID_FASTA" \
        -o "$ANI_TSV" \
        --filter "$FLTR" \
        --out-ani 0.95 \
        --out-qcov 0.85

    # Step 4: vclust cluster + extract representatives
    echo "==> [4/5] vclust cluster + extracting representatives..."
    vclust cluster \
        -i "$ANI_TSV" \
        -o "$CLUSTERS_TSV" \
        --ids "$ANI_IDS" \
        --algorithm cd-hit \
        --metric ani \
        --ani 0.95 \
        --qcov 0.85 \
        --out-repr

    awk '$1 == $2 {print $1}' "$CLUSTERS_TSV" | sort -u > "$CLUSTERS_LIST"
    seqkit grep -n -f "$CLUSTERS_LIST" "$HYBRID_FASTA" > "$CLUSTERS_FASTA"

    # Step 5: sylph sketch
    echo "==> [5/5] Sketching clustered database with sylph..."
    sylph sketch \
        "$CLUSTERS_FASTA" \
        -c 100 \
        -i \
        -o "$SYLPH_DB"

    echo ""
    echo "==> build-db complete!"
    echo "==> Sylph database: $SYLPH_DB"
    echo ""
    echo "    Pass this to profile with: --sylph-db $SYLPH_DB"
    exit 0
fi


#  profile subcommand

if [[ "$SUBCOMMAND" == "profile" ]]; then

    if [[ -z "$SYLPH_DB_INPUT" ]]; then
        echo "ERROR: --sylph-db is required for profile. Run 'build-db' first."
        usage
    fi

    if [[ ! -f "$SYLPH_DB_INPUT" ]]; then
        echo "ERROR: Sylph database not found: $SYLPH_DB_INPUT"
        exit 1
    fi

    if [[ -z "$FILE" && ( -z "$R1" || -z "$R2" ) ]]; then
        echo "ERROR: Provide either -f (single-end) or -R1 / -R2 (paired-end) reads."
        usage
    fi

    # Derive sample name
    if [[ -n "$FILE" ]]; then
        SAMPLE=$(basename "$FILE" | sed 's/\.fastq\.gz$//' | sed 's/\.fq\.gz$//' | sed 's/\.fastq$//' | sed 's/\.fq$//')
    else
        SAMPLE=$(basename "$R1" | sed 's/\.fastq\.gz$//' | sed 's/\.fq\.gz$//' | sed 's/\.fastq$//' | sed 's/\.fq$//' | sed 's/_R1//' | sed 's/_1$//')
    fi

    PROFILES_DIR="$OUTPUT/profiles"
    mkdir -p "$PROFILES_DIR"

    echo "==> [profile] Sample    : $SAMPLE"
    echo "==> [profile] Sylph DB  : $SYLPH_DB_INPUT"
    echo "==> [profile] Output    : $PROFILES_DIR"
    echo ""

    # Optional: ViromeQC
    if [[ "$run_viromeqc" == true ]]; then
        echo "==> Running ViromeQC..."
        if [[ -n "$FILE" ]]; then
            viromeqc.py \
                -i "$FILE" \
                -o "$PROFILES_DIR/${SAMPLE}_viromeqc.tsv" \
                --threads "$THREADS"
        else
            viromeqc.py \
                -i "$R1" "$R2" \
                -o "$PROFILES_DIR/${SAMPLE}_viromeqc.tsv" \
                --threads "$THREADS"
        fi
    fi

    # sylph profile
    echo "==> Profiling with sylph..."
    if [[ -n "$FILE" ]]; then
        sylph profile \
            -c 100 \
            -u \
            --min-number-kmers 20 \
            --min-count-correct 1 \
            --min-spacing 10 \
            "$SYLPH_DB_INPUT" \
            "$FILE" \
            -t "$THREADS" \
            > "$PROFILES_DIR/${SAMPLE}_sylph.tsv"
    else
        sylph profile \
            -c 100 \
            -u \
            --min-number-kmers 20 \
            --min-count-correct 1 \
            --min-spacing 10 \
            "$SYLPH_DB_INPUT" \
            -1 "$R1" \
            -2 "$R2" \
            -t "$THREADS" \
            > "$PROFILES_DIR/${SAMPLE}_sylph.tsv"
    fi

    echo ""
    echo "==> Done! Sylph profile: $PROFILES_DIR/${SAMPLE}_sylph.tsv"
    exit 0
fi
