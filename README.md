# Inviria

## A lightweight pipeline to profile the human virome

Inviria is a pipeline allows you to rapidly and efficiently profile viruses (prokaryotic and eukaryotic) from both human enriched Virus-like Particle (VLP) and bulk metagenomics sequencing data from short-read and long-read sequencing. Inviria extends virome profiling beyond the gut, delivering site-specific characterization of the oral, skin, and vaginal viromes through one streamlined pipeline.

This pipeline leverages:
- [viromeQC](https://github.com/SegataLab/viromeqc.git) to estimate viral enrichment from metagenomes.
- [sylph](https://github.com/bluenote-1577/sylph.git) for viral taxonomic profiling based on kmer ANI containment.

### Databases description
- Gut virome profiling:
  
We built an aggregated catalogue named the Inviria Human Gut Virome Database (IHGVD) which is a collection of 196,479 vOTUs that were preprocessed and clustered from the viral genomes in the comprehenstive Unified Human Gut Virome [UHGV](https://github.com/snayfach/UHGV.git) by [Nayfach et al.2025](https://www.biorxiv.org/content/10.1101/2025.11.01.686033v1), the AWI-Gen2 Microbiome Project that characterized 1,801 African metagenomes and reported by [Manghini et al. 2025](https://www.nature.com/articles/s41586-024-08485-8)  and the Chinese Gut Virome Catalogue [(cnGVC)] constructed from 11,286 bulk and viral-enriched metagenomes by [Yan et.al 2025](https://link.springer.com/article/10.1186/s13073-025-01460-6)

- Oral virome profiling:
  
The Human Oral Virome Database, published by [Xu et al.(2025)](https://www.sciencedirect.com/science/article/pii/S2666379125003982) is a collection of 24,523 vOTUs catalogued from 220 oral metagenomes as well as as oral viral genomes from the Oral Viral Database, the Cenote Human Virome Database and an oral virome subset from GenBank.

- Skin virome profiling:
  
We integrated the Skin Virome Database published by [Li et al.(2025)](https://journals.asm.org/doi/10.1128/spectrum.01178-25) which consists of 2,873 vOTUs constructed from 2,760 human skin metagenome samples .

- Vaginal virome profiling:
  
Vaginal virome profiling is performed against 4,263 vOTUs from the Human Vaginal Microbiome Genome Collection from [Huang et al.(2024)](https://www.nature.com/articles/s41564-024-01751-5) that was catalogued from 4,472 publicly available vaginal metagenomic samples.

#### Database annotation
For the IHGVD, taxonomic annotation and host prediction were performed against the [UHGV classifier](https://github.com/snayfach/UHGV-classifier) which is sensitive for viral genomes from the human gut. Taxonomic annotation for HOVD, SVD and VMGC vOTUs was performed using [geNomad] and host prediction using iPHOP (June 2025 database version). Viral lifestyle for all vOTUs was predicted using PHATYP.



### Installing Inviria

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
	-f  	    Single-end sequencing read file/long-read sequencing read file eg. ONT, PacBio
	--site-db	Body site database: gut (default), oral, skin, or vaginal
	-t          threads
	-o          output_dir
		  
    OPTIONAL ARGUMENTS
     -v  		            Run ViromeQC for viral enrichment analysis
     --no-filter            Write all taxonomy rows, not just contig-level
     --min-number-kmers     Minimum number of k-mers (default: 20)
     --min-count-correct    Minimum correct k-mer count (default: 1)
     --min-spacing          Minimum k-mer spacing (default: 10)

	 PIPELINE USAGE
     -h                     Show this help
}

### Expected Output
a) `vqc` : a directory containing the viral encrichment scores for all samples.

b) `output_abund_(gut/oral/skin/vaginal)_inviria.tsv.tsv` : a table in .tsv formart that summarizes the abundance of all mapped gut/oral/skin/vaginal vOTUs.




**Upcoming Features**
- Integrating a respiratory virome database.

