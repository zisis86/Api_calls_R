# BioInfoMiner

BioInfoMiner is an R package for interacting with the BioInfoMiner API. It helps create projects, run experiments, and fetch results.

## Installation

```R
# Install devtools if not already installed
install.packages("devtools")

# Install BioInfoMiner from GitHub
devtools::install_github("yourusername/BioInfoMinerLib")


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
