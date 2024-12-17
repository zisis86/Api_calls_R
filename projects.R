library(httr)
source("constant_variables.R")  # Assuming url is defined in this file

create_project <- function(headers, new_project) {
  print('-- Create a project in BioInfoMiner platform --')
  
  response <- POST(
    url = paste0(url, 'projects'),
    add_headers(.headers = headers),
    body = new_project,
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    project_id <- fromJSON(rawToChar(response$content))$projectId
    print(paste("New project ID:", project_id))
    return(project_id)
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
    return('')
  }
}

delete_project <- function(headers, project_id) {
  print(paste('-- Delete project with ID:', project_id, '--'))
  
  response <- DELETE(
    url = paste0(url, 'projects'),
    add_headers(.headers = headers),
    body = project_id,
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    print("Succesful deletion")
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
  }
}
