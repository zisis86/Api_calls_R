library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)

source("helpers.R")  # Contains transform_ontology_string, get_GO_subontologies, get_all_ontologies, isOntologyValid
source("constant_variables.R")  # Contains url, results_path 

#Function to get status
get_status_message <- function(status) {
  message_mapping <- list(
    'RUNNING' = "The tool's execution is not yet complete. Please try again later...",
    'FAILED' = "The tool's execution was unsuccessful.",
    'CANCELED' = "The tool's execution was canceled.",
    'COMPLETED' = "The tool's execution is completed."
  )
  return(message_mapping[[status]] %||% '')
}

empty_results <- function() {
  return(list(NULL, NULL, NULL, NULL))
}

#Function to get bioinfominer results
get_bim_results <- function(headers, experiment_id, ontology = "all") {
  get_drugs_for_bim_results <- function(gene_prioritization) {
    top_genes <- gene_prioritization$top_genes_configuration
    
    # Check validity of `top_genes`
    if (is.null(top_genes) || !is.list(top_genes)) {
      cat("Error: `top_genes_configuration` is not valid.\n")
      return(list())
    }
    
    # Ensure elements have `gene_symbol`
    if (!all(sapply(top_genes, function(x) is.list(x) && "gene_symbol" %in% names(x)))) {
      cat("Error: Some entries in `top_genes` do not contain `gene_symbol`.\n")
      return(list())
    }
    
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

