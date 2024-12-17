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

# Function to create a project
create_project <- function(title, description) {
  url <- paste0(base_url, "projects")
  body <- list(
    title = title,
    description = description
  )
  
  response <- POST(url, add_headers(.headers = headers), body = body, encode = "json")
  
  if (status_code(response) == 200) {
    content <- content(response, "parsed")
    project_id <- content$projectId
    cat("Project created with ID:", project_id, "\n")
    return(project_id)
  } else {
    stop("Error creating project: ", status_code(response), "\n", content(response, "text"))
  }
}

# Function to upload input dataset
get_input_dataset <- function(dataset_path) {
  dataset <- readLines(dataset_path)
  return(paste(dataset, collapse = "\n"))
}

# Function to create an experiment
create_bim_experiment <- function(headers, bim_input) {
  cat('-- BioInfoMiner experiment creation.. --\n')
  
  response <- POST(paste0(base_url, 'bimform'), add_headers(.headers = headers), body = bim_input, encode = "json")
  
  if (status_code(response) == 200) {
    experiment_id <- content(response)$experimentId
    cat("New experiment ID:", experiment_id, "\n")
    return(experiment_id)
  } else {
    cat("Error:", status_code(response), content(response, "text"), "\n")
    return('')
  }
}

#Function to run an experiment 
run_bim <- function(headers, execution_info) {    
  cat('-- BioInfoMiner execution (please wait).. --\n')
  
  response <- GET(paste0(base_url, 'runbim'), add_headers(.headers = headers), body = execution_info, encode = "json")
  
  if (status_code(response) == 200) {
    cat("Successful execution!\n")
  } else {
    cat("Error:", status_code(response), content(response, "text"), "\n")
    cat("Response Status Code:", status_code(response), "\n")
    cat("Response Content:\n", content(response, "text"), "\n")
  }
}

#Function to get the results 

get_bim_results <- function(headers, experiment_id, ontology = 'all') {
  
  get_bim_results_helper <- function(ontology, result_type) {
    gene_prioritization_results <- results$gene_prioritization[[ontology]]
    if (ontology == 'GO') {
      return(list(
        GO_Biological_Process = results$enrichment_analysis$GO$GO_P,
        GO_Molecular_Function = results$enrichment_analysis$GO$GO_F,
        GO_Cellular_Component = results$enrichment_analysis$GO$GO_C
      ), results$gene_prioritization$GO)
    } else {
      return(results$enrichment_analysis[[ontology]][[ontology]], results$gene_prioritization[[ontology]])
    }
  }
  
  cat('-- Result of BIM experiment with ID: ', experiment_id, ' --\n')
  
  proper_ontologies <- c('GO', 'Reactome', 'MGIMP', 'HPO', 'all')
  if (!(ontology %in% proper_ontologies)) {
    cat('This ontology is not available.\n')
    return(list())
  }
  
  response <- GET(paste0(base_url, 'results'), add_headers(.headers = headers), body = toJSON(experiment_id), encode = "json")
  
  if (status_code(response) == 200) {
    results <- fromJSON(content(response, "text"))
    if (results$status == 'RUNNING') {
      cat('The tool\'s execution is not yet complete. Please try again later...\n')
      return(list(NULL, NULL))
    } else if (results$status == 'FAILED') {
      cat('The tool\'s execution was unsuccessful.\n')
      return(list(NULL, NULL))
    } else if (results$status == 'COMPLETED') {
      cat('The tool\'s execution is completed.\n')
      if (ontology == 'all') {
        return(list(results$enrichment_analysis, results$gene_prioritization))
      } else if (ontology == 'GO') {
        # under construction
        return(list(NULL, NULL))
        # return get_bim_results_helper('GO')
      } else {
        # under construction
        return(list(NULL, NULL))
        # return get_bim_results_helper(ontology)
      }
    } else {
      return(list(NULL, NULL))
    }
  } else {
    cat("Error:", status_code(response), content(response, "text"), "\n")
    return(list(NULL, NULL))
  }
}