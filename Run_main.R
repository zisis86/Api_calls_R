# Main script execution
#sournce the functions from script
source("Functions.R")

# Step 1: Create a project
project_id <- create_project(
  title = "New project from R zisis",
  description = "A project created using R."
)

# Step 2: Get input dataset / Step 3: Create an experiment
input_ids <- get_input_dataset('input_dataset.csv')
bim_input <- list(
  title = 'Experiment',
  description = 'Experiment is created using R',
  project = project_id,
  parameters = list(
    input_ids = input_ids,
    fold_change_type = 'log',
    corrected_pvalue = 0.05,
    id_type = 'gene_symbol',
    organism = 'hsapiens'
  )
)
experiment_id <- create_bim_experiment(headers, bim_input)


# 3. run experiment
if (experiment_id != '') {
  execution_info <- list(
    experimentId = experiment_id,
    organism = 'hsapiens'
  )
  run_bim(headers, execution_info)
}




# 4. get results
experiment_id <- '674dc46cfdc0b47308e472ed'
enrichment_analysis_results <- get_bim_results(headers, experiment_id)
gene_prioritization_results <- enrichment_analysis_results[[2]]
print(names(gene_prioritization_results[['GO']]))


