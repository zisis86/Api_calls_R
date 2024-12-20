# Rscript main.R "https://bim3.e-nios.com/api/" "leq3vxq1812k4of6xrbdy2ekj43u4up3" "input_dataset.csv"

#Load helper functions
source("bioinfominer_functions.R")

# Parse command-line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript main.R <url> <api_key> <input_file>")
}

url <- args[1]
api_key <- args[2]
input_file <- args[3]

# Set headers
headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = api_key
)

# Create a project
new_project <- list(
  title = "TestProject",
  description = "A test project"
)
project_id <- create_project(headers, new_project)

if (project_id != "") {
  # Create an experiment
  input_ids <- readChar(input_file, file.info(input_file)$size)
  bim_input <- list(
    title = "TestExperiment",
    description = "A test experiment",
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
  
  # Run the experiment
  if (experiment_id != "") {
    execution_info <- list(
      experimentId = experiment_id,
      organism = "hsapiens"
    )
    run_bim(headers, execution_info)
    
    # Fetch and save results
    results <- get_bim_results(headers, experiment_id)
    if (!is.null(results[[1]])) {
      save_bim_results(results[[1]], results[[2]])
    }
  }
}
