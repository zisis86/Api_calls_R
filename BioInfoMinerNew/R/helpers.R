library(rlang)
transform_ontology_string <- function(ontology) {
  ontology_map <- list(
    go = "GO",
    reactome = "Reactome",
    mgimp = "MGIMP",
    hpo = "HPO"
  )
  return(ontology_map[[tolower(ontology)]] %||% "all")
}

get_GO_subontologies <- function() {
  subontologies <- paste0("GO_", c("P", "C", "F"))
  return(subontologies)
}

get_all_ontologies <- function(organism) {
  ontologies_map <- list(
    hsapiens = c("GO", "MGIMP", "Reactome", "HPO"),
    mmusculus = c("GO", "MGIMP", "Reactome"),
    rnorvegicus = c("GO", "MGIMP", "Reactome")
  )
  return(ontologies_map[[organism]])
}

isOntologyValid <- function(ontology, organism) {
  valid_ontologies <- c(get_all_ontologies(organism), "all")
  return(ontology %in% valid_ontologies)
}

# ------------------------------------------------------------------
# Prepare dataset text for API:
# - For symbol: return 1 column
# - For rnk:
#       2 columns -> return as-is
#       3+ columns -> return ONLY gene + 2nd column
# ------------------------------------------------------------------

prepare_dataset_for_api <- function(path, datatype) {
  ext <- tolower(tools::file_ext(path))

  # Load file
  if (ext %in% c("tsv", "txt")) {
    df <- tryCatch(
      read.delim(path, header = TRUE, stringsAsFactors = FALSE),
      error = function(e) {
        read.delim(path, header = FALSE, stringsAsFactors = FALSE)
      }
    )
  } else {
    df <- tryCatch(
      read.csv(path, header = TRUE, stringsAsFactors = FALSE),
      error = function(e) stop("Error reading dataset: ", e$message)
    )
  }

  # SYMBOL (gene list)
  if (datatype == "symbol") {
    if (ncol(df) > 1) {
      warning("Symbol datatype detected but file has multiple columns. Using first column only.")
    }
    df <- df[, 1, drop = FALSE]
  }

  # RNK (ranked list)
  if (datatype == "rnk") {
    if (ncol(df) == 2) {
      # OK as is
    } else if (ncol(df) >= 3) {
      message("Extracting gene column + 2nd column as ranking score.")
      df <- df[, c(1, 2)]
    }
  }

  # Convert back to plain text for API
  temp <- tempfile(fileext = ".csv")
  write.table(df, temp, sep = ",", row.names = FALSE, col.names = TRUE, quote = FALSE)

  # Read back as text string
  paste(readLines(temp, warn = FALSE), collapse = "\n")
}



# ------------------------------------------------------------------
# Detect dataset type automatically (supports CSV, TSV, TXT)
# 1 column  -> symbol
# 2 columns -> rnk
# 3+ columns -> rnk (score taken from 2nd column)
# ------------------------------------------------------------------

detect_datatype <- function(path) {
  if (!file.exists(path)) {
    stop("File not found: ", path)
  }

  ext <- tolower(tools::file_ext(path))

  # Choose reading method based on extension
  if (ext %in% c("tsv", "txt")) {
    df <- tryCatch(
      read.delim(path, header = TRUE, stringsAsFactors = FALSE),
      error = function(e) {
        read.delim(path, header = FALSE, stringsAsFactors = FALSE)
      }
    )
  } else {
    df <- tryCatch(
      read.csv(path, header = TRUE, stringsAsFactors = FALSE),
      error = function(e) stop("Error reading CSV/TXT/TSV file: ", e$message)
    )
  }

  cols <- ncol(df)

  if (cols == 1) {
    message("Detected datatype: symbol (single-column gene list)")
    return("symbol")
  }

  if (cols == 2) {
    message("Detected datatype: rnk (2-column ranked list)")
    return("rnk")
  }

  if (cols >= 3) {
    message("Detected datatype: rnk (multi-column input, using 2nd column as ranking score)")
    return("rnk")
  }

  stop("Unsupported file format: detected ", cols, " columns.")
}
