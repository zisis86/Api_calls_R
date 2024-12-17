# url = 'http://localhost:3000/api/'
url <- 'https://bim3.e-nios.com/api/'

headers <- list(
  'enios-api-key' = '',
  'Content-Type' = 'application/json'
)

results_path <- list(
  'ea' = './results/enrichment_analysis',
  'gp' = list(
    'top_genes' = './results/gene_prioritization/top_genes',
    'bottom_genes' = './results/gene_prioritization/bottom_genes',
    'clusters' = './results/gene_prioritization/clusters'
  ),
  'drugs' = './results/drugs'
)
