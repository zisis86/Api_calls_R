# Load required libraries
library(sys)
library(httr)
library(jsonlite)

# Define the API key
api_key <- "leq3vxq1812k4of6xrbdy2ekj43u4up3"

# Initialize headers
headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = api_key
)

# Source function files (update these paths to match your system)
source("projects.R")
source("experiments.R")
source("executions.R")
source("results.R")
source("constant_variables.R")

# Main function
main <- function() {
  # Use the hardcoded API key
  enios_api_key <- api_key
  
  # Update headers with the API key
  headers[["enios-api-key"]] <- enios_api_key
  
  # Example workflow
  
  # 1. Create a project
  new_project <- list(
    title = "New project from R22",
    description = "A project created using R"
  )
  project_id <- create_project(headers, new_project)
  
  # 2. Create an experiment
  input_ids <- get_input_dataset("./input_dataset.csv")  # Adjust the path to your dataset
  bim_input <- list(
    title = "Experiment",
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
  
  # 4. Get results
  load_bim_results(headers, experiment_id, "all")
  
  # 5. Delete the experiment
  delete_experiment(headers, experiment_id)
  
  # 6. Delete the project
  delete_project(headers, project_id)
}

# Execute the main function if the script is run directly
if (sys.nframe() == 0) {
  main()
}
