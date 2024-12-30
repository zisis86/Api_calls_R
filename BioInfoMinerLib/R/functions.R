library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)

# Constants
url <- "https://bim3.e-nios.com/api/"

# Functions
create_project <- function(headers, new_project) {
  print('-- Create a project in BioInfoMiner platform --')
  response <- POST(
    url = paste0(url, 'projects'),
    add_headers(.headers = headers),
    body = new_project,
    encode = "json"
  )
  if (status_code(response) == 200) {
    project_id <- fromJSON(rawToChar(response$content))$projectId
    print(paste("New project ID:", project_id))
    return(project_id)
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
    return('')
  }
}

create_bim_experiment <- function(headers, bim_input) {
  print('-- BioInfoMiner experiment creation --')
  response <- POST(
    url = paste0(url, 'bimform'),
    add_headers(.headers = headers),
    body = bim_input,
    encode = "json"
  )
  if (status_code(response) == 200) {
    experiment_id <- fromJSON(rawToChar(response$content))$experimentId
    print(paste("New experiment ID:", experiment_id))
    return(experiment_id)
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
    return('')
  }
}

run_bim <- function(headers, execution_info) {
  print('-- BioInfoMiner execution (please wait).. --')
  response <- GET(
    paste0(url, 'runbim'),
    add_headers(.headers = headers),
    query = execution_info
  )
  if (status_code(response) == 200) {
    print("Successful execution!")
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
  }
}

get_status_message <- function(status) {
  message_mapping <- list(
    'RUNNING' = "The tool's execution is not yet complete. Please try again later...",
    'FAILED' = "The tool's execution was unsuccessful.",
    'CANCELED' = "The tool's execution was canceled.",
    'COMPLETED' = "The tool's execution is completed."
  )
  return(message_mapping[[status]] %||% 'Unknown status')
}

empty_results <- function() {
  return(list(NULL, NULL, NULL, NULL))
}

get_bim_results <- function(headers, experiment_id) {
  response <- GET(paste0(url, "results"),
                  add_headers(.headers = headers),
                  query = list(experimentId = experiment_id))
  if (status_code(response) == 200) {
    results <- fromJSON(rawToChar(response$content))
    status <- results$status
    cat(get_status_message(status), "\n")
    if (status == "COMPLETED") {
      enrichment_analysis <- results$enrichment_analysis
      gene_prioritization <- results$gene_prioritization
      return(list(enrichment_analysis, gene_prioritization))
    }
  } else {
    cat("Error:", status_code(response), content(response, "text"), "\n")
    return(empty_results())
  }
}

save_bim_results <- function(enrichment_analysis, gene_prioritization) {
  # Save enrichment_analysis
  write.csv(as.data.frame(enrichment_analysis), "enrichment_analysis.csv", row.names = FALSE)
  # Save gene_prioritization
  write.csv(as.data.frame(gene_prioritization), "gene_prioritization.csv", row.names = FALSE)
}
