# Main wrapper function
run_bioinfominer <- function(url, api_key, input_file) {
  headers <- c(
    `Content-Type` = "application/json",
    `enios-api-key` = api_key
  )

  new_project <- list(
    title = "TestProject",
    description = "A test project"
  )
  project_id <- create_project(headers, new_project)

  if (project_id != "") {
    input_ids <- readChar(input_file, file.info(input_file)$size)
    bim_input <- list(
      title = "TestExperiment",
      description = "A test experiment",
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
      execution_info <- list(
        experimentId = experiment_id,
        organism = "hsapiens"
      )
      run_bim(headers, execution_info)

      results <- get_bim_results(headers, experiment_id)
      if (!is.null(results[[1]])) {
        save_bim_results(results[[1]], results[[2]])
      }
    }
  }
}
