# Load helper functions
# Load the installed package
if (!requireNamespace("BioInfoMinerNew", quietly = TRUE)) {
  stop("Package 'BioInfoMinerNew' is not installed. Install it first.")
}
library(BioInfoMinerNew)

# Define headers
headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = "your_api_key"
)

# Create a project
new_project <- list(
  title = "Example Project",
  description = "A demo project"
)
project_id <- create_project(headers, new_project)

if (project_id != "") {
  # Create an experiment
  input_ids <- readChar("inst/examples/input_dataset.csv", file.info("inst/examples/input_dataset.csv")$size)
  bim_input <- list(
    title = "Example Experiment",
    description = "A demo experiment",
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

  if (experiment_id != "") {
    # Run the experiment
    execution_info <- list(
      experimentId = experiment_id,
      organism = "hsapiens"
    )
    run_bim(headers, execution_info)

    # Fetch and save results
    results <- get_bim_results(headers, experiment_id)
    if (!is.null(results)) {
      save_bim_results(results[[1]], results[[2]])
    }
  }
}
