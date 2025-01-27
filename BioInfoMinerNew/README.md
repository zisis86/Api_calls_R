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
devtools::install_github("zisis86/Api_calls_R", subdir = "BioInfoMinerLib", auth_token = "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")


#Usage
#Load the Library
library(BioInfoMinerLib)

#Example# Set headers
headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = "your_api_key"
)

# Create a project
project_id <- create_project(headers, list(title = "My Project", description = "Description"))

# Create an experiment
experiment_id <- create_bim_experiment(headers, list(
  title = "My Experiment",
  description = "Description",
  project = project_id,
  parameters = list(
    input_ids = "gene1\ngene2",
    fold_change_type = "log",
    corrected_pvalue = 0.05,
    id_type = "gene_symbol",
    organism = "hsapiens"
  )
))

# Run the experiment
run_bim(headers, list(experimentId = experiment_id, organism = "hsapiens"))

# Get and save results
results <- get_bim_results(headers, experiment_id)
save_bim_results(results[[1]], results[[2]])
