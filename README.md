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

To run the pipeline, use the following commands while still in the repository directory

To profile the virome of paired-end short-read metagenomic reads:

	bash run_inviria.sh -R1 sample_R1.fastq.gz -R2 sample_R2.fastq.gz -t 16 -o output_dir --site-db gut/oral/skin/vaginal

To profile the virome of single_ended/long-read metagenomic reads:

	bash run_inviria.sh -f sample.fastq.gz -t 16 -o output_dir --site-db gut/oral/skin/vaginal


Input sequencing reads can be in `.fastq` or `.fastq.gz` formart.


Parameters


    REQUIRED ARGUMENTS    
    -R1 	    Forward read in fastq or fastq.gz format
    -R2 	    Reserve read in fastq or fastq.gz format
	-f  	    Single-end sequencing read file/long-read sequencing read file eg. nanopore
	--site-db	Body site database: gut (default), oral, skin, or vaginal"
	-t          threads
	-o          output_dir
		  
    OPTIONAL ARGUMENTS
     -v  		            Run ViromeQC for viral enrichment analysis
     --no-filter            Write all taxonomy rows, not just contig-level
     --min-number-kmers     Minimum number of k-mers (default: 20)
     --min-count-correct    Minimum correct k-mer count (default: 1)
     --min-spacing          Minimum k-mer spacing (default: 10)"

	 PIPELINE USAGE
     -h                     Show this help
}

### Expected Output
a) `vqc` : a directory containing the viral encrichment scores for all samples.

b) `output_abund_(gut/oral/skin/vaginal)_inviria.tsv.tsv` : a table in .tsv formart that summarizes the abundance of all mapped gut/oral/skin/vaginal vOTUs.




**Upcoming Features**
- Integrating a respiratory virome database.

