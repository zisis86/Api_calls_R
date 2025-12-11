library(rlang)

# ------------------------------------------------------------
# Ontology utilities
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
    hsapiens    = c("GO", "MGIMP", "Reactome", "HPO"),
    mmusculus   = c("GO", "MGIMP", "Reactome"),
    rnorvegicus = c("GO", "MGIMP", "Reactome")
  )
  return(ontologies_map[[organism]])
}

isOntologyValid <- function(ontology, organism) {
  valid_ontologies <- c(get_all_ontologies(organism), "all")
  return(ontology %in% valid_ontologies)
}

# ------------------------------------------------------------
# Extract first column from any input file (CSV, TSV, TXT)
# and return a clean gene list for input_ids mode
# ------------------------------------------------------------

extract_gene_list <- function(path) {

  if (!file.exists(path)) {
    stop("File does not exist: ", path)
  }

  ext <- tolower(tools::file_ext(path))

  # Try reading with header = TRUE, fallback to header = FALSE
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

  # Always extract the FIRST column as genes
  genes <- df[, 1]

  # Remove empty rows
  genes <- genes[genes != "" & !is.na(genes)]

  # Return newline-separated gene list (for input_ids)
  paste(genes, collapse = "\n")
}
