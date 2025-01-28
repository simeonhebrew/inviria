import pandas as pd
import matplotlib.pyplot as plt

# Load the data from the tab-separated file, specifying the tab delimiter
file_path = 'OUTPUT/merged_output_file.txt'  # Replace with your file path
data = pd.read_csv(file_path, sep='\t', usecols=[0, 6], header=0)

# Rename columns for easier reference
data.columns = ['X', 'Y']

data['X'] = data['X'].str.split('_').str[0]

# Plot the data
plt.figure(figsize=(10, 6))
plt.bar(data['X'], data['Y'], color='skyblue')
plt.xlabel('Samples')
plt.ylabel('Total Enrichment Score')
plt.title('ViromeQC Enrichment Score Summary')
plt.xticks(rotation=90, ha='right')  # Rotate x-axis labels for better readability
plt.tight_layout()  # Adjust layout to fit x-axis labels


plt.savefig('bar_graph_viromeqc.png', format='png', dpi=300)

# Show the plot
plt.show()
