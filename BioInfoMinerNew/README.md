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
# BioInfoMiner R Library

BioInfoMiner is an R package that provides programmatic access to the BioInfoMiner platform,
allowing users to create projects, run experiments, retrieve results, and explore systemic
biological interpretations directly from R.

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

## Installation

```r
install.packages("remotes")

remotes::install_github(
  "zisis86/Api_calls_R",
  subdir = "BioInfoMinerNew"
)

library(BioInfoMinerNew)
```

---

## Authentication

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
project_id <- create_project(
  headers,
  list(
    title       = "My Project",
    description = "Created via BioInfoMiner R package"
  )
)
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
  description = "Experiment created from R",
  project     = project_id,
  parameters  = list(
    input_ids        = input_ids,
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
execution_info <- list(
  experimentId = experiment_id,
  organism     = "hsapiens"
)

run_bim(headers, execution_info)
```

### 5. Wait for completion and retrieve results

```r
results <- wait_for_bim_completion(
  headers,
  experiment_id,
  ontology   = "GO",
  max_checks = 10,
  delay_sec  = 20
)
```

### 6. Save results locally

```r
save_bim_results(
  enrichment_analysis = results[[1]],
  gene_prioritization = results[[2]],
  drugs               = results[[3]],
  ontology            = "all",
  organism            = results[[4]]
)
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

Timeout errors usually indicate that the experiment is still running.
Use `wait_for_bim_completion()` to poll until results are ready.

---

## Contact

E-NIOS Bioinformatics Services  
Email: zisis@e-nios.com  
Website: https://www.e-nios.com/

