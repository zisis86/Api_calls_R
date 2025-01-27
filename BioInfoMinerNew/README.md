# BioInfoMiner Library 

Goal: BioInfoMiner is an R package for interacting with the BioInfoMiner API. It helps create projects, run experiments, and fetch results.
GitHub: https://github.com/zisis86/Api_calls_R/tree/main/BioInfoMinerLib
Language: R 

Implementation of the tool includes four sections: 
1) Projects : Creations / Delete of a Project.
2) Experiments : Creation / Delete an Experiment.
3) Executions : Run / Execute an Experiment. 
4) Results : Get and Save the Results.

The repository in Github contains the following files:
- R repository: Includes the script **functions.R ** with the functions for the execution of each section and  **main.R** with the base script of the tool.
- DESCRIPTION :  This file provides overall metadata about the package.
- NAMESPACE : Defines the functions, classes, and methods that are imported into the package namespace, and exported for users.

R Studio Environment:
It is recommended to use R Studio environment for the installation and execution of the Library. 


## Installation

```R
# Install devtools if not already installed
install.packages("devtools")

# Install BioInfoMiner from GitHub
devtools::install_github("zisis86/Api_calls_R", subdir = "BioInfoMinerNew", auth_token = "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")
or
install.packages("/path/to/BioInfoMinerNew_0.1.0.tar.gz", repos = NULL, type = "source")


#Usage
#Load the Library
library(BioInfoMinerNew)

#Example# Set headers

api_key <- "your api_key"
headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = api_key
)

# 1. Create a project
project_id <- create_project(headers, list(title = "My Project", description = "Description"))

# 2. Create an experiment
input_ids <- get_input_dataset("/Path/to/your/input/input_dataset.csv")  # Adjust the path to your dataset
bim_input <- list(
  title = "Experiment_1908",
  description = "Experiment created using R.",
  project = project_id,
  parameters = list(
    input_ids = input_ids,
    fold_change_type = "log",
    corrected_pvalue = 0.05,
    id_type = "gene_symbol",
    organism = "hsapiens"
  )
)
experiment_id <- create_bim_experiment(headers, bim_input)

# 3. Run the experiment
if (experiment_id != "") {
  execution_info <- list(
    experimentId = experiment_id,
    organism = "hsapiens"
  )
  run_bim(headers, execution_info)
}


# 4. Get and save results
results <- get_bim_results(headers, experiment_id)
print(results)  # Should return a list of enrichment_analysis, gene_prioritization, drugs, and organism
save_bim_results(results[[1]], results[[2]])

# Test Save_bim_results with a small example  
#Mock Input Data: Test a  small data for enrichment_analysis, gene_prioritization, and drugs
enrichment_analysis <- list(sample_data = "example")
gene_prioritization <- list(top_genes_configuration )
drugs <- list(list(gene = "BRCA1", drugs = list(list(name = "Drug1"), list(name = "Drug2"))))
ontology <- "all"
organism <- "human"

# Test the saving function
save_bim_results(enrichment_analysis, gene_prioritization, drugs, ontology, organism)
