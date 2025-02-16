#This script modifies the sylph output to a user-friendly table for downstream analysis

import csv

def categorize_taxonomy(clade_name):
    
    clade_name = clade_name.replace(',', '|')
    
    
    terms = clade_name.split('|')

    # Here we are interested in organizing all classifications levels in column order; both viral and host classification as well as lifestyle
    categories = {
        'Realm': [],
        'Kingdom': [],
        'Phylum': [],
        'Class': [],
        'Order': [],
        'Family': [],
        'Genus': [],
        'Contigs': [],  
        'Host_Bacteria': [],
        'Host_Phylum': [],
        'Host_Class': [],
        'Host_Order': [],
        'Host_Family': [],
        'Host_Genus': [],
        'Host_Species': [],
        'Lifestyle': [],
    }

    #Then we move to  move lifestyle categories to their respective  columns
    for term in terms:
        # Check for lifestyle terms
        if 'lytic' in term or 'temperate' in term or 'chronic' in term:
            categories['Lifestyle'].append(term)
        
        #Assigning viral host classification to their columns with the help of 'n__' labels
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

        # Doing the same but for viral classification, here we benefit from the fact that their suffixes can be used to assign them
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

        # We then add the UHGV vOTU names to the contigs column
        if 'UHGV' in term:
            categories['Contigs'].append(term)

    return categories
#Organizing the final output file
def process_file(input_file_path, output_file_path):
    try:
        
        with open(input_file_path, 'r') as input_file:
            reader = csv.DictReader(input_file, delimiter='\t')
            fieldnames = reader.fieldnames

            
            if 'clade_name' not in fieldnames:
                raise ValueError("'clade_name' column not found in the input file")

            
            categorized_rows = []

           
            for row in reader:
                clade_name = row.get('clade_name', '').strip() 
                if not clade_name:
                    continue  

                
                categorized_taxonomy = categorize_taxonomy(clade_name)

                
                new_row = {key: row[key] for key in row if key != 'clade_name'}  

                
                for category, terms in categorized_taxonomy.items():
                    new_row[category] = ','.join(terms)  

                
                if 'UHGV' in new_row['Contigs']:
                    categorized_rows.append(new_row)

            
            new_fieldnames = ['Realm', 'Kingdom', 'Phylum', 'Class', 'Order', 'Family', 'Genus', 'Contigs',
                              'Host_Bacteria', 'Host_Phylum', 'Host_Class', 'Host_Order', 'Host_Family', 'Host_Genus', 'Host_Species', 'Lifestyle'] + [col for col in fieldnames if col != 'clade_name']

        # We finally save the output file
        with open(output_file_path, 'w', newline='') as output_file:
            writer = csv.DictWriter(output_file, fieldnames=new_fieldnames, delimiter='\t')
            writer.writeheader()
            writer.writerows(categorized_rows)

        print(f"The final abundance table has been written to {output_file_path}")
    except Exception as e:
        print(f"Oops!An error has occurred: {e}")


input_file_path = 'merged_abundance_uhgv_host.tsv'  
output_file_path = 'output_abund_uhgv_host_inviria.tsv'  


process_file(input_file_path, output_file_path)
