library(rlang)

# ------------------------------------------------------------
# Ontology utilities (unchanged)
# ------------------------------------------------------------

transform_ontology_string <- function(ontology) {
  ontology_map <- list(
    go       = "GO",
    reactome = "Reactome",
    mgimp    = "MGIMP",
    hpo      = "HPO"
  )
  return(ontology_map[[tolower(ontology)]] %||% "all")
}

get_GO_subontologies <- function() {
  subontologies <- paste0("GO_", c("P", "C", "F"))
  return(subontologies)
}

get_all_ontologies <- function(organism) {
  ontologies_map <- list(
    hsapiens     = c("GO", "MGIMP", "Reactome", "HPO"),
    mmusculus    = c("GO", "MGIMP", "Reactome"),
    rnorvegicus  = c("GO", "MGIMP", "Reactome")
  )
  return(ontologies_map[[organism]])
}

isOntologyValid <- function(ontology, organism) {
  valid_ontologies <- c(get_all_ontologies(organism), "all")
  return(ontology %in% valid_ontologies)
}

# ------------------------------------------------------------
# UNIVERSAL gene-input loader for input_ids mode
# Works for: CSV, TSV, TXT, 1+ columns, with/without header
# Always extracts ONLY the FIRST column as gene list
# ------------------------------------------------------------

get_input_dataset <- function(path) {
  if (!file.exists(path)) {
    stop("File does not exist: ", path)
  }

  ext <- tolower(tools::file_ext(path))

  # Try with header = TRUE, fallback to header = FALSE
  df <- tryCatch({
      if (ext %in% c("tsv", "txt")) {
        read.delim(path, header = TRUE, stringsAsFactors = FALSE)
      } else {
        read.csv(path, header = TRUE, stringsAsFactors = FALSE)
      }
    },
    error = function(e) {
      if (ext %in% c("tsv", "txt")) {
        read.delim(path, header = FALSE, stringsAsFactors = FALSE)
      } else {
        read.csv(path, header = FALSE, stringsAsFactors = FALSE)
      }
    }
  )

  # Use only first column as gene IDs
  gene_column <- df[, 1]

  # Drop empty / NA
  gene_column <- gene_column[gene_column != "" & !is.na(gene_column)]

  # Return newline-separated list of genes
  paste(gene_column, collapse = "\n")
}
