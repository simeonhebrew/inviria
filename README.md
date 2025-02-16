# Inviria

## A lightweight pipeline to profile the human gut virome

Inviria allows you to rapidly quantify and profile enriched human gut viral samples.


### Quick Start!

### Installation

a) To install inviria, first clone the git repository to your preferred directory and move into the repository

	git clone https://github.com/simeonhebrew/inviria.git
	cd inviria

b) Using the configuration file provided, create a new conda environment:

	conda env create -n inviria --file inviria.yml


c) Activate the conda environment

	conda activate inviria


d)Download the required database

`curl https://zenodo.org/records/14879780/files/votus_full.syldb?download=1 --output votus_full.syldb`



### Usage

To run the pipeline, use the the following command while still in the repository directory

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
a) 
