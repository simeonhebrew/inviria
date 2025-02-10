import csv

def categorize_taxonomy(clade_name):
    # Split the clade_name by the '|' character
    terms = clade_name.split('|')
    
    # Define the categories (remove 'Life' and 'vOTUs' from categories)
    categories = {
        'Realm': [],
        'Kingdom': [],
        'Phylum': [],
        'Class': [],
        'Order': [],
        'Family': [],
        'Genus': [],
        'Contigs': []  # Only keep 'Contigs' here
    }

    # Iterate over each term and categorize it based on the rules
    for term in terms:
        if 'UHGV' in term:
            categories['Contigs'].append(term)  # Add to the 'Contigs' category
        elif term.endswith('ia'):
            categories['Realm'].append(term)
        elif term.endswith('virae'):
            categories['Kingdom'].append(term)
        elif term.endswith('ota'):
            categories['Phylum'].append(term)
        elif term.endswith('etes'):
            categories['Class'].append(term)
        elif term.endswith('ales'):
            categories['Order'].append(term)
        elif term.endswith('viridae'):
            categories['Family'].append(term)
        elif term.endswith('virus'):
            categories['Genus'].append(term)

    return categories

def process_file(input_file_path, output_file_path):
    # Open the input CSV file and read its contents
    with open(input_file_path, 'r') as input_file:
        reader = csv.DictReader(input_file, delimiter = '\t')
        fieldnames = reader.fieldnames

        # Check if the 'clade_name' column exists
        if 'clade_name' not in fieldnames:
            raise ValueError("'clade_name' column not found in the input file")

        # Prepare to store the categorized data
        categorized_rows = []

        # Process each row
        for row in reader:
            clade_name = row['clade_name']
            # Categorize the clade_name
            categorized_taxonomy = categorize_taxonomy(clade_name)
            
            # Create a new row with all original columns and the categorized columns
            new_row = {key: row[key] for key in row if key != 'clade_name'}  # Remove 'clade_name' column
            
            # Add the categorized data as new columns (without 'Life' and 'vOTUs')
            for category, terms in categorized_taxonomy.items():
                new_row[category] = ','.join(terms)  # Join multiple terms with commas if necessary

            # Only keep rows with 'UHGV' in the Contigs column
            if 'UHGV' in new_row['Contigs']:
                categorized_rows.append(new_row)

        # Define the new column order (taxonomy columns first, followed by the original columns)
        new_fieldnames = ['Realm', 'Kingdom', 'Phylum', 'Class', 'Order', 'Family', 'Genus', 'Contigs'] + [col for col in fieldnames if col != 'clade_name']

    # Write the output to a new TSV file
    with open(output_file_path, 'w', newline='') as output_file:
        writer = csv.DictWriter(output_file, fieldnames=new_fieldnames, delimiter='\t')
        writer.writeheader()
        writer.writerows(categorized_rows)

    print(f"Processed data has been written to {output_file_path}")

# File paths to your input and output files
input_file_path = '/content/merged_abundance.tsv'  # Change this to the path of your input file
output_file_path = '/content/output_taxx_filtered_no_life_votus.tsv'  # Change this to where you want to save the output

# Process the file
process_file(input_file_path, output_file_path)
