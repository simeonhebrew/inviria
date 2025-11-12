# Inviria

## A lightweight pipeline to profile the human virome

Inviria is a pipeline allows you to rapidly and efficienty quantify and profile the human virome from both enriched Virus-like Particle (VLP) and bulk metagenomics sequencing data.
It leverages [viromeQC](https://github.com/SegataLab/viromeqc.git) to estimate viral enrichment and [sylph](https://github.com/bluenote-1577/sylph.git) for viral and host taxonomic profiling against the Unified Human Gut Virome [UHGV](https://github.com/snayfach/UHGV.git) for human gut virome profiling, the Human Oral Virome Database [HOVD](https://github.com/willmaxu/Human-oral-virome-database?tab=readme-ov-file) for human oral virome profiling and the Human Vaginal Microbiome Genome Collection [VMGC](https://github.com/RChGO/VMGC) for human vaginal virome profiling.


### Installation

a) To install inviria, first clone the git repository to your preferred directory and move into the repository

	git clone https://github.com/simeonhebrew/inviria.git
	cd inviria

b) Using the configuration file provided, create a new [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/getting-started.html) environment:

	conda env create -n inviria --file inviria.yml


c) Activate the conda environment

	conda activate inviria


d) Download the reference database

	curl https://zenodo.org/records/14937019/files/votus_full_100.syldb\?download\=1 --output votus_full_100.syldb



### Usage

To run the pipeline, use the following command while still in the repository directory

`./inviria_pe_se.sh -R1 <forward read> -R2 <reverse read> -t <threads> -o <output_directory>`

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
- Integrating a skin virome database.
- Prediction of integrated prophages from sequencing reads.
- Viral protein abundance profiling
