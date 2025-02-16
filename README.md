# Inviria

## A lightweight pipeline to profile the human gut virome

Inviria is a pipeline allows you to rapidly and efficienty quantify and profile the human gut virome from enriched Virus-like Particle (VLP) sequencing data.
It leverages [viromeQC](https://github.com/SegataLab/viromeqc.git) to estimate viral enrichment, [sylph](https://github.com/bluenote-1577/sylph.git) for taxonomic profiling and the Unified Human Gut Virome [UHGV](https://github.com/snayfach/UHGV.git), a comprehensive resource of viruses that have been clustered from 
independent human microbiome studies.


### Installation

a) To install inviria, first clone the git repository to your preferred directory and move into the repository

	git clone https://github.com/simeonhebrew/inviria.git
	cd inviria

b) Using the configuration file provided, create a new [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/getting-started.html) environment:

	conda env create -n inviria --file inviria.yml


c) Activate the conda environment

	conda activate inviria


d) Download the reference database

	curl https://zenodo.org/records/14879780/files/votus_full.syldb?download=1 --output votus_full.syldb



### Usage

To run the pipeline, use the following command while still in the repository directory

`./inviria.sh -R1 <forward read> -R2 <reverse read> -t <threads> -o <output_directory>`

Input sequencing reads can be in `.fastq` or `.fastq.gz` formart.


Parameters

	REQUIRED ARGUMENTS
	  -R1, --Read1        Forward read in fastq or fastq.gz format
	  -R2, --Read2        Reverse read in fastq or fastq.gz format
	  -t, --threads       Specify number of threads for parallel processing
	OPTIONAL ARGUMENTS
	  -o, --output        Output directory
	  -v                  Run ViromeQC for viral enchrichment scores
	PIPELINE USAGE
	  -h, --help          list all arguments

### Expected Output
a) `ViromeQC_Viral_Enrichment_Score.png` : a bar graph plot showing the viral enrichment scores of all your samples.

b) `viral_host_lifestyle_abund_inviria.tsv` : a table in .tsv formart that summarizes the abundance of all mapped UHGV vOTUs.




**Upcoming Features**
- Allowing for long read sequencing read profiling.
- Viral gene catalogue abundance profiling.
