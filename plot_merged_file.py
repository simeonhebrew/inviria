#Plotting the summarized output file from viromeQC

import pandas as pd
import matplotlib.pyplot as plt

file_path = 'OUTPUT/merged_output_file.txt' 
data = pd.read_csv(file_path, sep='\t', usecols=[0, 6], header=0)


data.columns = ['X', 'Y']

data['X'] = data['X'].str.split('_').str[0]


plt.figure(figsize=(10, 6))
plt.bar(data['X'], data['Y'], color='skyblue')
plt.xlabel('Samples')
plt.ylabel('Total Enrichment Score')
plt.title('ViromeQC Enrichment Score Summary')
plt.xticks(rotation=90, ha='right') 
plt.tight_layout() 


plt.savefig('ViromeQC_Viral_Enrichment_Score.png', format='png', dpi=300)

plt.show()
