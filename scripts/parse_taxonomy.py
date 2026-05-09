#!/usr/bin/env python3
"""
Inviria – Taxonomy Table Formatter
Parses sylph-tax clade_name strings into structured viral taxonomy,
host taxonomy, lifestyle, and abundance columns.

Author: Simeon Hebrew Nthuku
"""

import csv
import argparse
from pathlib import Path



# Taxonomy parsing rules


VIRAL_SUFFIX_MAP = {
    'ia':      'Realm',
    'virae':   'Kingdom',
    'ota':     'Phylum',
    'etes':    'Class',
    'ales':    'Order',
    'viridae': 'Family',
    'virus':   'Genus',
}

VIRAL_PREFIX_TO_COL = {
    'r__': 'Realm',
    'k__': 'Kingdom',
    'p__': 'Phylum',
    'c__': 'Class',
    'o__': 'Order',
    'f__': 'Family',
    'g__': 'Genus',
}

HOST_PREFIX_MAP = {
    'p__': 'Host_Phylum',
    'c__': 'Host_Class',
    'o__': 'Host_Order',
    'f__': 'Host_Family',
    'g__': 'Host_Genus',
    's__': 'Host_Species',
}

LIFESTYLE_TERMS = {'virulent', 'temperate', 'unknown'}

TAXONOMY_COLUMNS = [
    'Contigs', 'Realm', 'Kingdom', 'Phylum', 'Class', 'Order', 'Family', 'Genus',
    'Host_Bacteria', 'Host_Phylum', 'Host_Class', 'Host_Order',
    'Host_Family', 'Host_Genus', 'Host_Species', 'Lifestyle',
]



# Helpers


def strip_prefix(term: str) -> str:
    """Strip taxonomic prefix (e.g. f__, g__, k__) from a term if present."""
    return term.split('__', 1)[-1] if '__' in term else term



# Setting the core passing logic


def parse_clade_name(clade_name: str) -> dict:
    """
    Parse a pipe- or comma-delimited clade_name string into taxonomy categories.

    Priority order:
        1. t__           → Contigs
        2. lifestyle     → Lifestyle
        3. d__Bacteria   → Host_Bacteria + switches to host context
        4. host context  → host prefix map (prefix retained)
        5. viral suffix  → viral taxonomy column (prefix stripped)
        6. Unclassified  → viral prefix map (prefix stripped)

    Args:
        clade_name: The raw clade_name string from sylph-tax output.

    Returns:
        Dictionary with taxonomy category keys and list values.
    """
    clade_name = clade_name.replace(',', '|')
    terms = [t.strip() for t in clade_name.split('|') if t.strip()]

    categories = {col: [] for col in TAXONOMY_COLUMNS}

    in_host_context = False

    for term in terms:

        # 1. Contig
        if term.startswith('t__'):
            contig_id = term[3:]
            if contig_id:
                categories['Contigs'].append(contig_id)
            continue

        # 2. Lifestyle
        if any(lt in term.lower() for lt in LIFESTYLE_TERMS):
            categories['Lifestyle'].append(term)
            continue

        # 3. Host context trigger
        if term.startswith('d__'):
            in_host_context = True
            categories['Host_Bacteria'].append(term)
            continue

        # 4. Host taxonomy — everything after d__Bacteria (prefix retained)
        if in_host_context:
            for prefix, col in HOST_PREFIX_MAP.items():
                if term.startswith(prefix):
                    categories[col].append(term)
                    break
            continue

        # 5. Viral taxonomy (suffix-based, prefix stripped)
        matched_viral = False
        for suffix, col in VIRAL_SUFFIX_MAP.items():
            if term.endswith(suffix):
                categories[col].append(strip_prefix(term))
                matched_viral = True
                break

        if matched_viral:
            continue

        # 6. Unclassified viral placeholders (prefix stripped)
        if 'nclassified' in term:
            for prefix, col in VIRAL_PREFIX_TO_COL.items():
                if term.startswith(prefix):
                    categories[col].append(strip_prefix(term))
                    break

    return categories


def format_categories(categories: dict) -> dict:
    """Join list values into comma-separated strings."""
    return {k: ','.join(v) for k, v in categories.items()}



# File processing


def process_file(
    input_path: str,
    output_path: str,
    filter_by_contig: bool = True,
) -> None:
    """
    Parse a sylph-tax merged abundance TSV and write a structured taxonomy table.

    Args:
        input_path:       Path to input TSV file.
        output_path:      Path to output TSV file.
        filter_by_contig: If True, only rows where a t__ contig was parsed are written.
    """
    input_path  = Path(input_path)
    output_path = Path(output_path)

    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(input_path, 'r') as infile:
        reader = csv.DictReader(infile, delimiter='\t')

        if 'clade_name' not in reader.fieldnames:
            raise ValueError("'clade_name' column not found in input file.")

        abundance_cols    = [col for col in reader.fieldnames if col != 'clade_name']
        output_fieldnames = TAXONOMY_COLUMNS + abundance_cols

        rows_written = 0

        with open(output_path, 'w', newline='') as outfile:
            writer = csv.DictWriter(outfile, fieldnames=output_fieldnames, delimiter='\t')
            writer.writeheader()

            for row in reader:
                clade_name = row.get('clade_name', '').strip()
                if not clade_name:
                    continue

                categories = format_categories(parse_clade_name(clade_name))

                if filter_by_contig and not categories['Contigs']:
                    continue

                out_row = {**categories, **{col: row[col] for col in abundance_cols}}
                writer.writerow(out_row)
                rows_written += 1

    print(f"Done. {rows_written} rows written to {output_path}")


 
# Arguments for running on CLI


def parse_args():
    parser = argparse.ArgumentParser(
        description="Inviria – Parse sylph-tax clade_name into structured taxonomy table."
    )
    parser.add_argument(
        '-i', '--input',
        required=True,
        help="Path to merged sylph-tax abundance TSV (e.g. merged_abundance_gut_virome.tsv)"
    )
    parser.add_argument(
        '-o', '--output',
        required=True,
        help="Path to write the output taxonomy table TSV"
    )
    parser.add_argument(
        '--no-filter',
        action='store_true',
        help="Write all rows, not just those containing a parsed t__ contig"
    )
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    process_file(
        input_path=args.input,
        output_path=args.output,
        filter_by_contig=not args.no_filter,
    )
