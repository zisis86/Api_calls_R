# Verify API URL and Endpoint
print(headers)

response <- GET(
  paste0(url, "results"),
  add_headers(.headers = headers),
  body = experiment_id,
  encode = "json"
)

##Error in curl::curl_fetch_memory(url, handle = handle) : 
#Timeout was reached [bim3.e-nios.com]: Failed to connect to bim3.e-nios.com port 443 after 10005 ms: Timeout was reached

# Validate Experiment ID
response <- GET(
  paste0(url, "status"),
  add_headers(.headers = headers),
  query = list(experimentId = experiment_id)
)

status_code <- status_code(response)
if (status_code == 200) {
  print(fromJSON(rawToChar(response$content)))
} else {
  cat("Error:", status_code, content(response, "text"), "\n")
}

#Debug the GET Request 
response <- GET(
  paste0(url, "results"),
  add_headers(.headers = headers),
  body = experiment_id,
  encode = "json"
)

print(content(response, "text"))

#No encoding supplied: defaulting to UTF-8.
#[1] "Internal Server Error"

#Test Minimal Request 
test_experiment_id <- "6762e49b7b91845894c2aee7"  # Replace with valid ID
response <- GET(
  paste0(url, "results"),
  add_headers(.headers = headers),
  body = test_experiment_id,
  encode = "json"
)

cat("Status Code:", status_code(response), "\n")
cat("Response Body:", content(response, "text"), "\n")

###Example Debugging TEST
library(httr)
library(jsonlite)

url <- "https://bim3.e-nios.com/api/"  # Update with actual base URL
headers <- c(
  `Content-Type` = "application/json",
  `enios-api-key` = "leq3vxq1812k4of6xrbdy2ekj43u4up3"  # Replace with your API key
)

experiment_id <- "6762e49b7b91845894c2aee7"  # Replace with actual experiment ID

response <- GET(
  paste0(url, "results"),
  add_headers(.headers = headers),
  encode = "json"
)

response <- GET(
  url = paste0(url, "results"),
  add_headers(.headers = headers),
  query = list(experimentId = experiment_id)  # Include experiment_id as a query parameter
)


status_code <- status_code(response)
if (status_code == 200) {
  results <- fromJSON(rawToChar(response$content))
  print(results)
} else {
  cat("Error:", status_code, content(response, "text"), "\n")
}

response <- GET(paste0(url, "results"), 
                add_headers(.headers = headers), 
                body = experiment_id, 
                encode = "json")
###
response <- GET(paste0(url, 'results'), 
                add_headers(.headers = headers), 
                query = execution_info)
