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
