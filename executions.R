library(httr)
source("constant_variables.R")  # Assuming url is defined in this file

run_bim <- function(headers, execution_info) {
  print('-- BioInfoMiner execution (please wait).. --')
  
  #response <- GET(url = paste0(url, 'runbim'),add_headers(.headers = headers),body = execution_info, encode = "json")
  
  response <- GET(paste0(url, 'runbim'), add_headers(.headers = headers), query = execution_info)

  
  if (status_code(response) == 200) {
    print("Successful execution!")
  } else {
    print(paste("Error:", status_code(response), content(response, "text")))
  }
}
