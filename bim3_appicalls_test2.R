# Load required libraries
library(httr)
library(jsonlite)

# Define constants
base_url <- "https://bim3.e-nios.com/api/"
api_key <- "leq3vxq1812k4of6xrbdy2ekj43u4up3"

headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = api_key
)

# Helper function to read dataset
get_input_dataset <- function(file_path) {
  file_content <- readLines(file_path)
  paste(file_content, collapse = "\n")
}

# Function to create a project
create_project <- function(headers, project_data) {
  cat("-- Creating project.. --\n")
  response <- POST(
    url = paste0(base_url, "projects"),
    add_headers(.headers = headers),
    body = toJSON(project_data, auto_unbox = TRUE)
  )
  
  if (response$status_code == 200) {
    project_id <- content(response)$projectId
    cat("New project ID:", project_id, "\n")
    return(project_id)
  } else {
    cat("Error:", response$status_code, content(response, as = "text"), "\n")
    return("")
  }
}

# Function to create a BioInfoMiner experiment
create_bim_experiment <- function(headers, bim_input) {
  cat("-- Creating BioInfoMiner experiment.. --\n")
  response <- POST(
    url = paste0(base_url, "bimform"),
    add_headers(.headers = headers),
    body = toJSON(bim_input, auto_unbox = TRUE)
  )
  
  if (response$status_code == 200) {
    experiment_id <- content(response)$experimentId
    cat("New experiment ID:", experiment_id, "\n")
    return(experiment_id)
  } else {
    cat("Error:", response$status_code, content(response, as = "text"), "\n")
    return("")
  }
}

# Function to run the experiment
run_bim <- function(headers, execution_info) {
  cat("-- Running experiment.. --\n")
  response <- POST(
    url = paste0(base_url, "executions"),
    add_headers(.headers = headers),
    body = toJSON(execution_info, auto_unbox = TRUE)
  )
  
  if (response$status_code == 200) {
    cat("Experiment executed successfully.\n")
  } else {
    cat("Error:", response$status_code, content(response, as = "text"), "\n")
  }
}

# Main script execution
# Step 1: Create a project
new_project <- list(
  title = "New project from R",
  description = "A project created using R"
)

project_id <- create_project(headers, new_project)

# Step 2: Create an experiment if the project creation was successful
if (project_id != "") {
  input_dataset <- get_input_dataset("input_dataset.csv")
  
  bim_input <- list(
    title = "BimRAPIcalls project",
    description = "Experiment is created using R.",
    project = project_id,
    parameters = list(
      input_ids = input_dataset,
      fold_change_type = "log",
      corrected_pvalue = 0.05,
      id_type = "gene_symbol",
      organism = "hsapiens"
    )
  )
  
  experiment_id <- create_bim_experiment(headers, bim_input)
  
  # Step 3: Run the experiment if experiment creation was successful
  if (experiment_id != "") {
    execution_info <- list(
      experimentId = experiment_id,
      organism = "hsapiens"
    )
    run_bim(headers, execution_info)
  }
}
