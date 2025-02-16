import csv

def categorize_taxonomy(clade_name):
    # Replace all commas with pipes first
    clade_name = clade_name.replace(',', '|')
    
    # Split the clade_name by the '|' character
    terms = clade_name.split('|')

    # Define the categories (keep both previous and new categories)
    categories = {
        'Realm': [],
        'Kingdom': [],
        'Phylum': [],
        'Class': [],
        'Order': [],
        'Family': [],
        'Genus': [],
        'Contigs': [],  # Only keep 'Contigs' here
        'Host_Bacteria': [],
        'Host_Phylum': [],
        'Host_Class': [],
        'Host_Order': [],
        'Host_Family': [],
        'Host_Genus': [],
        'Host_Species': [],
        'Lifestyle': [],
    }

    # Iterate over each term and categorize it based on the rules
    for term in terms:
        # Check for lifestyle terms
        if 'lytic' in term or 'temperate' in term:
            categories['Lifestyle'].append(term)
        
        # Check for specific prefixes and assign to appropriate category
        elif term.startswith('d__'):
            categories['Host_Bacteria'].append(term)
        elif term.startswith('p__'):
            categories['Host_Phylum'].append(term)
        elif term.startswith('c__'):
            categories['Host_Class'].append(term)
        elif term.startswith('o__'):
            categories['Host_Order'].append(term)
        elif term.startswith('f__'):
            categories['Host_Family'].append(term)
        elif term.startswith('g__'):
            categories['Host_Genus'].append(term)
        elif term.startswith('s__'):
            categories['Host_Species'].append(term)

        # Assign terms to previous taxonomy categories based on suffixes
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

        # Add to Contigs if 'UHGV' is in the term
        if 'UHGV' in term:
            categories['Contigs'].append(term)

    return categories

def process_file(input_file_path, output_file_path):
    try:
        # Open the input CSV file and read its contents
        with open(input_file_path, 'r') as input_file:
            reader = csv.DictReader(input_file, delimiter='\t')
            fieldnames = reader.fieldnames

            # Check if the 'clade_name' column exists
            if 'clade_name' not in fieldnames:
                raise ValueError("'clade_name' column not found in the input file")

            # Prepare to store the categorized data
            categorized_rows = []

            # Process each row
            for row in reader:
                clade_name = row.get('clade_name', '').strip()  # Handle empty clade_name gracefully
                if not clade_name:
                    continue  # Skip rows with empty clade_name

                # Categorize the clade_name
                categorized_taxonomy = categorize_taxonomy(clade_name)

                # Create a new row with all original columns and the categorized columns
                new_row = {key: row[key] for key in row if key != 'clade_name'}  # Remove 'clade_name' column

                # Add the categorized data as new columns
                for category, terms in categorized_taxonomy.items():
                    new_row[category] = ','.join(terms)  # Join multiple terms with commas if necessary

                # Only keep rows with 'UHGV' in the Contigs column
                if 'UHGV' in new_row['Contigs']:
                    categorized_rows.append(new_row)

            # Define the new column order (taxonomy columns first, followed by the original columns)
            new_fieldnames = ['Realm', 'Kingdom', 'Phylum', 'Class', 'Order', 'Family', 'Genus', 'Contigs',
                              'Host_Bacteria', 'Host_Phylum', 'Host_Class', 'Host_Order', 'Host_Family', 'Host_Genus', 'Host_Species', 'Lifestyle'] + [col for col in fieldnames if col != 'clade_name']

        # Write the output to a new TSV file
        with open(output_file_path, 'w', newline='') as output_file:
            writer = csv.DictWriter(output_file, fieldnames=new_fieldnames, delimiter='\t')
            writer.writeheader()
            writer.writerows(categorized_rows)

        print(f"Processed data has been written to {output_file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

# File paths to your input and output files
input_file_path = 'merged_abundance_uhgv_host.tsv'  # Change this to the path of your input file
output_file_path = 'output_abund_uhgv_host_inviria.tsv'  # Change this to where you want to save the output

# Process the file
process_file(input_file_path, output_file_path)
