# Load required libraries
library(httr)
library(jsonlite)

# Define constants
url <- "https://bim3.e-nios.com/api/"
api_key <- "leq3vxq1812k4of6xrbdy2ekj43u4up3"
headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = api_key
)

headers <- add_headers(
  'enios-api-key' = 'leq3vxq1812k4of6xrbdy2ekj43u4up3',  # Replace with your API key if available
  'Content-Type' = 'application/json'
)
# Function to create a project

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
# Function to delete a project

delete_project <- function(headers, project_id) {
  print(paste('-- Delete project with ID:', project_id, '--'))
  
  response <- DELETE(
    url = paste0(url, 'projects'),
    add_headers(.headers = headers),
    body = project_id,
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    print("Succesful deletion")
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
  }
}

# # Function to upload input dataset and Function to create an experiment

get_input_dataset <- function(dataset_name) {
  csv_content <- readChar(dataset_name, file.info(dataset_name)$size)
  return(csv_content)
}

create_bim_experiment <- function(headers, bim_input) {
  print('-- BioInfoMiner experiment creation.. --')
  
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
#Function to delete an experiment
delete_experiment <- function(headers, experiment_id) {
  print(paste('-- Delete experiment with ID:', experiment_id, '--'))
  
  response <- DELETE(
    url = paste0(url, 'experiments'),
    add_headers(.headers = headers),
    body = experiment_id,
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    print("Succesful deletion")
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
  }
}

# Function to run an experiment 

run_bim <- function(headers, execution_info) {
  print('-- BioInfoMiner execution (please wait).. --')
  
  #response <- GET(
  # url = paste0(url, 'runbim'),
  # add_headers(.headers = headers),
  #  body = execution_info,
  #  encode = "json"
  #  )
  response <- GET(paste0(url, 'runbim'), add_headers(.headers = headers), query = execution_info)
  
  if (status_code(response) == 200) {
    print("Successful execution!")
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
  }
}

# Function to get the results 
library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)

source("helpers.R")  # Contains transform_ontology_string, get_GO_subontologies, get_all_ontologies, isOntologyValid
source("constant_variables.R")  # Contains url, results_path

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

get_bim_results <- function(headers, experiment_id, ontology = "all") {
  get_drugs_for_bim_results <- function(gene_prioritization) {
    top_genes <- gene_prioritization$top_genes_configuration
    gene_symbols <- sapply(top_genes, function(x) x$gene_symbol)
    gene_symbols <- unique(gene_symbols)
    response <- GET(paste0(url, "drugs"), 
                    add_headers(.headers = headers), 
                    query = list(genes = toJSON(gene_symbols)))
    
    if (status_code(response) == 200) {
      results <- fromJSON(rawToChar(response$content))
      return(results$genesDrugs)
    } else {
      cat("Error:", status_code(response), content(response, "text"), "\n")
      return(list())
    }
  }
  
  cat("-- Results of BIM experiment with ID: ", experiment_id, " --\n")
  
  response <- GET(paste0(url, "results"),
                  add_headers(.headers = headers),
                  query = list(experimentId = experiment_id))
  

  ####
  if (status_code(response) == 200) {
    results <- fromJSON(rawToChar(response$content))
    status <- results$status
    cat(get_status_message(status), "\n")
    
    if (status == "COMPLETED") {
      organism <- results$organism
      
      if (!isOntologyValid(ontology, organism)) {
        cat("This ontology is not available.\n")
        return(empty_results())
      }
      
      enrichment_analysis <- results$enrichment_analysis
      gene_prioritization <- results$gene_prioritization
      
      if (ontology == 'all') {
        drugs <- list()
        ontologies <- get_all_ontologies(organism)
        for (ont in ontologies) {
          current_drugs <- get_drugs_for_bim_results(gene_prioritization[[ont]])
          drugs <- c(drugs, current_drugs)
        }
      } else {
        drugs <- get_drugs_for_bim_results(gene_prioritization[[ontology]])
      }
      
      return(list(enrichment_analysis, gene_prioritization, drugs, organism))
    } else {
      return(empty_results())
    }
  } else {
    cat("Error:", status_code(response), content(response, "text"), "\n")
    return(empty_results())
  }
}

create_results_dirs <- function() {
  dir.create(results_path$ea, showWarnings = FALSE, recursive = TRUE)
  dir.create(results_path$gp$top_genes, showWarnings = FALSE, recursive = TRUE)
  dir.create(results_path$gp$bottom_genes, showWarnings = FALSE, recursive = TRUE)
  dir.create(results_path$gp$clusters, showWarnings = FALSE, recursive = TRUE)
  dir.create(results_path$drugs, showWarnings = FALSE, recursive = TRUE)
}

save_bim_results <- function(enrichment_analysis, gene_prioritization, drugs, ontology, organism) {
  save_ea_helper <- function(enrichment_analysis, ontology) {
    ea_df <- as.data.frame(enrichment_analysis)
    ea_df$genes <- sapply(ea_df$genes, paste, collapse = "; ")
    write.csv(ea_df, file = file.path(results_path$ea, paste0(ontology, ".csv")), row.names = FALSE)
  }
  
  save_gp_helper <- function(gene_prioritization, ontology) {
    gp_top_genes_df <- as.data.frame(gene_prioritization$top_genes_configuration)
    gp_top_genes_df$drugs <- NULL
    gp_top_genes_df$cluster_ids <- gsub("\\[|\\]", "", gp_top_genes_df$cluster_ids)
    gp_top_genes_df$cluster_ids <- gsub(",", ";", gp_top_genes_df$cluster_ids)
    
    gp_bottom_genes_df <- as.data.frame(gene_prioritization$bottom_genes_configuration)
    gp_bottom_genes_df$cluster_ids <- gsub("\\[|\\]", "", gp_bottom_genes_df$cluster_ids)
    gp_bottom_genes_df$cluster_ids <- gsub(",", ";", gp_bottom_genes_df$cluster_ids)
    
    gp_clusters_df <- as.data.frame(gene_prioritization$clusters_configuration)
    gp_clusters_df$genes <- sapply(gp_clusters_df$genes, paste, collapse = "; ")
    gp_clusters_df$members <- sapply(gp_clusters_df$members, paste, collapse = "; ")
    
    write.csv(gp_top_genes_df, file = file.path(results_path$gp$top_genes, paste0(ontology, ".csv")), row.names = FALSE)
    write.csv(gp_bottom_genes_df, file = file.path(results_path$gp$bottom_genes, paste0(ontology, ".csv")), row.names = FALSE)
    write.csv(gp_clusters_df, file = file.path(results_path$gp$clusters, paste0(ontology, ".csv")), row.names = FALSE)
  }
  
  save_drugs_helper <- function(drugs) {
    for (gene in drugs) {
      if (length(gene$drugs) > 0) {
        drugs_df <- as.data.frame(gene$drugs)
        drugs_df$`_id` <- NULL
        write.csv(drugs_df, file = file.path(results_path$drugs, paste0(gene$gene, ".csv")), row.names = FALSE)
      }
    }
  }
  
  save_results_based_on_ontology <- function(enrichment_analysis, gene_prioritization, drugs, ontology) {
    current_ontologies <- if(ontology == 'GO') get_GO_subontologies() else ontology
    for (current_ontology in current_ontologies) {
      current_ea <- enrichment_analysis[[ontology]][[current_ontology]]
      save_ea_helper(current_ea, current_ontology)
    }
    current_gp <- gene_prioritization[[ontology]]
    save_gp_helper(current_gp, ontology)
    save_drugs_helper(drugs)
  }
  
  create_results_dirs()
  
  if (ontology == 'all') {
    ontologies <- get_all_ontologies(organism)
    for (ont in ontologies) {
      save_results_based_on_ontology(enrichment_analysis, gene_prioritization, drugs, ont)
    }
  } else {
    save_results_based_on_ontology(enrichment_analysis, gene_prioritization, drugs, ontology)
  }
}

load_bim_results <- function(headers, experiment_id, ontology) {
  ontology <- transform_ontology_string(ontology)
  results <- get_bim_results(headers, experiment_id, ontology)
  enrichment_analysis <- results[[1]]
  gene_prioritization <- results[[2]]
  drugs <- results[[3]]
  organism <- results[[4]]
  
  if (!is.null(enrichment_analysis)) {
    save_bim_results(enrichment_analysis, gene_prioritization, drugs, ontology, organism)
  }
}

#####CHECK the results 
#Testing Each Function
# 1. Create a project
new_project <- list(
  title = "New project from R_1908",
  description = "A project created using R"
)
project_id <- create_project(headers, new_project)

# 2. Create an experiment
input_ids <- get_input_dataset("input_dataset.csv")  # Adjust the path to your dataset
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

# Valid statuses
print(get_status_message('RUNNING'))     # Expected: "The tool's execution is not yet complete. Please try again later..."
print(get_status_message('COMPLETED'))   # Expected: "The tool's execution is completed."

# Invalid status
print(get_status_message('INVALID'))     # Expected: "" or "Unknown status"

print(empty_results())  # Expected: list(NULL, NULL, NULL, NULL)

#3. get_bim_results test
experiment_id <-"6763f75f1f4fdf4298f50760"
headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = api_key
)
print(headers)
print(experiment_id)
print(ontology)
ontology <- "GO"

results <- get_bim_results(headers, experiment_id)
print(results)  # Should return a list of enrichment_analysis, gene_prioritization, drugs, and organism
print(url)
results
#Test Invalid Experiment ID:
experiment_id <- 'invalid_id'
results <- get_bim_results(headers, experiment_id)
print(results)  # Should print an error message and return empty results
#4. Save_bim_results
#Mock Input Data: Prepare mock data for enrichment_analysis, gene_prioritization, and drugs
enrichment_analysis <- list(sample_data = "example")
gene_prioritization <- list(top_genes_configuration = data.frame(gene_symbol = c("BRCA1", "TP53")))
drugs <- list(list(gene = "BRCA1", drugs = list(list(name = "Drug1"), list(name = "Drug2"))))
ontology <- "all"
organism <- "human"

# Test the saving function
save_bim_results(enrichment_analysis, gene_prioritization, drugs, ontology, organism)

#5. load_bim_results
#Mock headers and IDs, and verify if results are loaded and saved correctly:
headers <- c('Authorization' = 'Bearer example_token')  # Replace with valid token
experiment_id <- '12345'
ontology <- 'all'

load_bim_results(headers, experiment_id, ontology)
# Check if files are saved to the correct directories


############################ Test the response###################################
tryCatch({
  response <- GET(paste0(url, "results"), add_headers(.headers = headers), query = list(experimentId = experiment_id))
}, error = function(e) {
  cat("Error in API call:", e$message, "\n")
  return(empty_results())
})


#Enable verbose logging to inspect the request and response details:

response <- GET(
  paste0(url, "results"), 
  add_headers(.headers = headers), 
  timeout(30), 
  verbose()
)
cat("Response Content:", content(response, "text"), "\n")

##Debugging with Test Calls 
response <- GET(
  paste0(url, "results"),
  add_headers(.headers = headers),
  timeout(30)
)

if (status_code(response) == 200) {
  cat("Success! Parsing results...\n")
  results <- fromJSON(rawToChar(response$content))
  print(results)
} else {
  cat("Error:", status_code(response), content(response, "text"), "\n")
}

#Make a test with minimal parameters 
response <- GET(
  paste0(url, "results"),
  add_headers(.headers = headers),
  query = list(experiment_id = '6763f75f1f4fdf4298f50760'),
  timeout(30)
)
print(status_code(response))
print(content(response, "text"))
