import pandas as pd
import numpy as np
import os
import re



def trim_taxa_names(taxa_name):
    return re.sub(r'^[kpcofgst]__', "", str(taxa_name))

def extract_taxonomic_columns(df, rank):
    df_taxa = df['clade_name'].str.split('|', expand=True)
    taxonomic_levels = ["Realm", "Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species", "Contig"]
    taxonomic_rank_mapping = {rank: index + 1 for index, rank in enumerate(taxonomic_levels)}
    rank_index = taxonomic_rank_mapping.get(rank, 9) 
    selected_taxa_cols = taxonomic_levels[:rank_index]
    df_taxa.columns = selected_taxa_cols
    for col in df_taxa.columns:
        df_taxa[col] = df_taxa[col].apply(trim_taxa_names)
    df_taxa['vOTU'] = ["vOTU" + str(i) for i in range(len(df))]
    for col in selected_taxa_cols:
        df_taxa.at[df_taxa.index[-1], col] = 'Other'
    return df_taxa


def add_otu_identifier(df):
  df['vOTU'] = ["vOTU" + str(i) for i in range(len(df))]
  return df




input_file = "/content/merged_abundance_file_control.tsv"
df = pd.read_csv(input_file, sep='\t')

df_known_clades = df[df['clade_name'].str.contains(r'\;|t__[^;]*$', na=False)]

abundance_matrix = add_otu_identifier(df_known_clades)


species_taxa = extract_taxonomic_columns(abundance_matrix, 'Strains')


species_taxa['Species'] = species_taxa['Class'] + '_' + species_taxa['Contig']

merged_df = pd.concat([species_taxa, abundance_matrix.drop(columns='clade_name')], axis=1)


output_abundance_file = '/content/controlsylph22_abund.csv'
output_taxa_file = '/content/controlsylph22_taxa.csv'
output_merged_file = '/content/mergedcontrolsylph22_taxa.csv'


abundance_matrix.to_csv(output_abundance_file, index=False)
species_taxa.to_csv(output_taxa_file, index=False)
merged_df.to_csv(output_merged_file, index=False)



print(f"Files saved: {output_abundance_file} , {output_taxa_file} and {output_merged_file}")
