library(httr)
source("constant_variables.R")  # Assuming url is defined in this file

get_input_dataset <- function(dataset_name) {
  csv_content <- readChar(dataset_name, file.info(dataset_name)$size)
  return(csv_content)
}

create_bim_experiment <- function(headers, bim_input) {
  print('-- BioInfoMiner experiment creation.. --')
  
  response <- POST(
    url = paste0(url, 'bimform'),
    add_headers(.headers = headers),
    body = bim_input,
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    experiment_id <- fromJSON(rawToChar(response$content))$experimentId
    print(paste("New experiment ID:", experiment_id))
    return(experiment_id)
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
    return('')
  }
}

delete_experiment <- function(headers, experiment_id) {
  print(paste('-- Delete experiment with ID:', experiment_id, '--'))
  
  response <- DELETE(
    url = paste0(url, 'experiments'),
    add_headers(.headers = headers),
    body = experiment_id,
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    print("Succesful deletion")
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
  }
}
