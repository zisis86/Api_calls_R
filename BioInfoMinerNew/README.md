# BioInfoMiner Library 

Goal: BioInfoMiner is an R package for interacting with the BioInfoMiner API. It helps create projects, run experiments, and fetch results.
GitHub: https://github.com/zisis86/Api_calls_R/edit/main/BioInfoMinerNew  

Implementation of the tool includes the following sections that enables you to:
- Projects : Create BioInfoMiner projects / Delete of a Project.
- Data : Upload datasets  
- Executions/Experiments: Create and run experiments / Delete an Experiment / Wait for execution to finish  
- Results : Retrieve analysis results / Get & Save results locally in structured folders 


The repository in Github contains the following files:
- R repository: Includes the script **functions.R ** with the functions for the execution of each section and  **main.R** with the base script of the tool.
- DESCRIPTION :  This file provides overall metadata about the package.
- NAMESPACE : Defines the functions, classes, and methods that are imported into the package namespace, and exported for users.

R Studio Environment:
 Language: R | It is recommended to use R Studio environment for the installation and execution of the Library. 

GitHub repository:
https://github.com/zisis86/Api_calls_R

---

## Overview

With BioInfoMiner you can:

- Create and manage BioInfoMiner projects
- Upload and process biological datasets
- Run enrichment and gene prioritization experiments
- Retrieve and store analysis results locally
- Interactively explore results using a DAG-based viewer

---

## Package Structure

```text
BioInfoMinerNew/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── functions.R
│   ├── helpers.R
│   ├── constant_variables.R
│   └── systemic_viewer.R
├── inst/
│   └── examples/
│       └── Onlygenes_CSV.json
└── README.md
```

---
functions.R contains the main API-facing functions.
helpers.R and constant_variables.R define internal helpers and paths.

## Installation

```r
install.packages("remotes")

remotes::install_github(
  "zisis86/Api_calls_R",
  subdir = "BioInfoMinerNew"
)

#Load the Library
library(BioInfoMinerNew)
```

---

## Set API Key

```r
api_key <- "YOUR_API_KEY_HERE"

headers <- c(
  `Content-Type`  = "application/json",
  `enios-api-key` = api_key
)
```

---

## Typical API Workflow

### 1. Create a project

```r
project_id <- create_project(headers, list(title = "My Project", description = "Testing BioInfoMiner API from R"))

```

### 2. Load an input gene dataset

```r
gene_file <- "path/to/genes.csv"
input_ids <- get_input_dataset(gene_file)
```

### 3. Create an experiment

```r
bim_input <- list(
  title       = "Example Experiment",
  description = "Experiment created using R",
  project     = project_id,
  parameters  = list(
    input_ids        = input_ids,    # unified gene list input
    fold_change_type = "log",
    corrected_pvalue = 0.05,
    id_type          = "gene_symbol",
    organism         = "hsapiens"
  )
)

experiment_id <- create_bim_experiment(headers, bim_input)
```

### 4. Run the experiment

```r
if (experiment_id != "") {
  execution_info <- list(
    experimentId = experiment_id,
    organism     = "hsapiens"
  )
  run_bim(headers, execution_info)   # returns quickly now
}
```

### 5. Wait for completion and retrieve results

```r
results <- wait_for_bim_completion(
  headers,
  experiment_id,
  ontology   = "GO",   # or "all", "BP", "MF", etc.
  max_checks = 10,     # number of retries
  delay_sec  = 20      # seconds between retries
)
```

### 6. Get and Save results locally

```r

#get_bim_results() always returns a list of 4 elements:
#[[1]] = enrichment_analysis (or NULL if not ready)
#[[2]] = gene_prioritization (or NULL)
#[[3]] = drugs (or NULL)
#[[4]] = organism (or NULL)

#When the experiment is not completed, it returns something like:
#list(NULL, NULL, NULL, NULL)


if (!is.null(results[[1]])) {
  enrichment_analysis <- results[[1]]
  gene_prioritization <- results[[2]]
  drugs               <- results[[3]]
  organism            <- results[[4]]
  
  save_bim_results(
    enrichment_analysis = enrichment_analysis,
    gene_prioritization = gene_prioritization,
    drugs               = drugs,
    ontology            = "all",
    organism            = organism
  )
  
  cat("Results saved successfully.\n")
}



# Alternative Results save
results <- get_bim_results(headers, experiment_id, ontology = "all")

if (!is.null(results[[1]])) {
  enrichment_analysis <- results[[1]]
  gene_prioritization <- results[[2]]
  drugs               <- results[[3]]
  organism            <- results[[4]]   # use the real organism returned

  ontology <- "all"

  save_bim_results(
    enrichment_analysis = enrichment_analysis,
    gene_prioritization = gene_prioritization,
    drugs               = drugs,
    ontology            = ontology,
    organism            = organism
  )

  print("Results saved successfully.")
} else {
  print("No results available yet (experiment not completed or API issue).")
}

#The saving logic is inside save_bim_results() and create_results_dirs(), which use a results_path object defined in constant_variables.R.
#So your CSV files will be in folders like: results/enrichment_analysis/ , results/gp/top_genes/, results/gp/bottom_genes/ etc

list.files(results_path$ea)
list.files(results_path$gp$top_genes)
list.files(results_path$gp$bottom_genes)
list.files(results_path$gp$clusters)
list.files(results_path$drugs)


#🔄 Alternative: Automatically Fetch + Save Results
#If you prefer a single command that both retrieves results and writes them to disk, you can use:

load_bim_results(headers, experiment_id, ontology = "all")

##Example: Using load_bim_results()
# Example usage (replace placeholders with real values)

# Your API headers
headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = "YOUR_API_KEY_HERE"
)

# The ID of a completed experiment
experiment_id <- "YOUR_EXPERIMENT_ID"   # e.g. "6754ab3bf123..."

# Ontology ("all", "GO", "BP", "MF", etc.)
ontology <- "all"

# Fetch results and save them to the results/ folder
load_bim_results(headers, experiment_id, ontology)

cat("If the experiment has completed, results will be saved in the 'results/' directory.\n")
```

---

## Systemic Interpretation Viewer (DAG)

Interactive DAG viewer for BioInfoMiner results (GO / REACTOME / any ontology present).

### Run with the built-in example JSON

```r
library(BioInfoMinerNew)

bim_systemic_viewer(ontology = "GO")
```

### Run with your own JSON results file

```r
library(BioInfoMinerNew)

bim_systemic_viewer(
  json_path = "BioInfoMiner_results.json",
  ontology  = "REACTOME"
)
```

### Run using results already loaded in R

```r
library(BioInfoMinerNew)

bim_systemic_viewer(
  results  = results,
  ontology = "GO"
)
```

---

## Troubleshooting
_Error: 524 A timeout occurred_
_Timeout was reached: Operation too slow_

Those errors typically mean either The API request stayed open too long or the backend is still running the computation.
In cases like that:
1. Check the experiment in the BioInfoMiner web platform
2. Use wait_for_bim_completion(headers, experiment_id) to poll for completion
3. Once completed, use save_bim_results() or load_bim_results() to get the outputs

Timeout errors usually indicate that the experiment is still running.
Use `wait_for_bim_completion()` to poll until results are ready.

---

# Reinstall the library (local) and run it

From R, with your working directory at the repo root **or** using the full path:

```r
# If needed:
install.packages(c("shiny","visNetwork","jsonlite","htmltools"))

# Reinstall your package from the local folder:
install.packages("Api_calls_R/BioInfoMinerNew", repos = NULL, type = "source")

# Load and run:
library(BioInfoMinerNew)
bim_systemic_viewer(ontology = "GO")

## Contact

E-NIOS Bioinformatics Services  
Email: zisis@e-nios.com  
Website: https://www.e-nios.com/

