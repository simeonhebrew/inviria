from pathlib import Path
import pandas as pd
import argparse

def main():
    parser = argparse.ArgumentParser(
        description="Merge relative abundance TSV files into a single table."
    )
    parser.add_argument(
        "input_dir",
        type=Path,
        help="Directory containing the TSV profile files"
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="merged_relative_abundance.tsv",
        help="Output file path (default: merged_relative_abundance.tsv)"
    )
    args = parser.parse_args()

    input_dir = args.input_dir
    output_file = args.output

    if not input_dir.is_dir():
        raise ValueError(f"Input directory does not exist: {input_dir}")

    files = list(input_dir.glob("*.tsv"))
    if not files:
        raise ValueError(f"No TSV files found in: {input_dir}")

    merged_df = None
    for file in files:
        # Remove _sylph suffix from sample name if present
        sample_name = file.stem.removesuffix("_sylph")

        df = pd.read_csv(file, sep="\t")
        df.columns = df.columns.str.strip()
        df = df[["Contig_name", "Taxonomic_abundance"]].copy()
        df.rename(columns={"Taxonomic_abundance": sample_name}, inplace=True)

        if merged_df is None:
            merged_df = df
        else:
            merged_df = pd.merge(merged_df, df, on=["Contig_name"], how="outer")

    sample_cols = [c for c in merged_df.columns if c != "Contig_name"]
    merged_df[sample_cols] = merged_df[sample_cols].fillna(0)

    merged_df.to_csv(output_file, sep="\t", index=False)
    print(f"Merged table saved to: {output_file}")

if __name__ == "__main__":
    main()
