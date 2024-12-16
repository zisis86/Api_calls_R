# Load necessary libraries
library(httr)
library(jsonlite)

# Constants
base_url <- "https://bim3.e-nios.com/api/"
api_key <- "leq3vxq1812k4of6xrbdy2ekj43u4up3"

# Set up headers
headers <- add_headers(
  `Content-Type` = "application/json",
  `enios-api-key` = api_key
)

# Function to create a project
create_project <- function(headers, project_data) {
  url <- paste0(base_url, "projects")
  response <- POST(url, headers, body = toJSON(project_data, auto_unbox = TRUE))
  
  if (status_code(response) == 200) {
    project_id <- content(response, "parsed")$projectId
    cat("New project ID:", project_id, "\n")
    return(project_id)
  } else {
    cat("Error:", status_code(response), content(response, "text"), "\n")
    return(NULL)
  }
}

# Function to get input dataset
get_input_dataset <- function(file_path) {
  data <- read.csv(file_path, header = FALSE, stringsAsFactors = FALSE)
  return(data)
}

# Function to create a BioInfoMiner experiment
create_bim_experiment <- function(headers, experiment_data) {
  url <- paste0(base_url, "bimform")
  response <- POST(url, headers, body = toJSON(experiment_data, auto_unbox = TRUE))
  
  if (status_code(response) == 200) {
    experiment_id <- content(response, "parsed")$experimentId
    cat("New experiment ID:", experiment_id, "\n")
    return(experiment_id)
  } else {
    cat("Error:", status_code(response), content(response, "text"), "\n")
    return(NULL)
  }
}

# Main workflow
# 1. Create a project
project_data <- list(
  title = "BimRAPIcalls_new",
  description = "Project created using R script"
)

project_id <- create_project(headers, project_data)

if (!is.null(project_id)) {
  # 2. Load input dataset
  input_data <- get_input_dataset("input_dataset.csv")
  
  # 3. Prepare experiment data
  bim_input <- list(
    title = "Experiment",
    description = "Experiment created using R",
    project = project_id,
    parameters = list(
      input_ids = input_data,
      fold_change_type = "log",
      corrected_pvalue = 0.05,
      id_type = "gene_symbol",
      organism = "hsapiens"
    )
  )
  
  # 4. Create experiment
  experiment_id <- create_bim_experiment(headers, bim_input)
  
  if (!is.null(experiment_id)) {
    cat("Experiment successfully created with ID:", experiment_id, "\n")
  }
} else {
  cat("Failed to create project. Exiting workflow.\n")
}
