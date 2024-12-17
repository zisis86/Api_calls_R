library(sys)

source("projects.R")
source("experiments.R")
source("executions.R")
source("results.R")
source("constant_variables.R")

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  enios_api_key <- args[1]
  
  headers[["enios-api-key"]] <- enios_api_key
  
  # # 1. create a project
  # new_project <- list(
  #     title = "New project from python",
  #     description = "a project created using python"
  # )
  # project_id <- create_project(headers, new_project)
  
  # # 2. create experiment
  # input_ids <- get_input_dataset("./input_dataset.csv")
  # bim_input <- list(
  #     title = "Experiment",
  #     description = "Experiment is created using python.",
  #     project = project_id,
  #     parameters = list(
  #         input_ids = input_ids,
  #         fold_change_type = "log",
  #         corrected_pvalue = 0.05,
  #         id_type = "gene_symbol",
  #         organism = "hsapiens"
  #     )
  # )
  # experiment_id <- create_bim_experiment(headers, bim_input)
  
  # # 3. run experiment
  # if (experiment_id != "") {
  #     execution_info <- list(
  #         experimentId = experiment_id,
  #         organism = "hsapiens"
  #     )
  #     run_bim(headers, execution_info)
  # }
  
  # 4. get results
  experiment_id <- ""
  load_bim_results(headers, experiment_id, "all")
  
  # # 5. delete experiment
  # # experiment_id <- ""
  # delete_experiment(headers, experiment_id)
  
  # # 6. delete project
  # # project_id <- ""
  # delete_project(headers, project_id)
}

if (sys.nframe() == 0) {
  main()
}
