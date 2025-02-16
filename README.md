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

`curl https://zenodo.org/records/14879780/files/votus_full.syldb?download=1 --output votus_full.syldb



### Usage

./inviria.sh -R1 -R2
