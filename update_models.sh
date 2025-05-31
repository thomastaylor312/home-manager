#!/bin/bash

# Define the output file
OUTPUT_FILE="files/available_models.json"

# Fetch the model list from the OpenRouter API
# Use -s for silent mode to suppress progress meter and error messages
# Use -L to follow redirects, if any
echo "Fetching model list from OpenRouter API..."
api_response=$(curl --fail -sL https://openrouter.ai/api/v1/models)

# Check if curl command was successful and output is not empty
if [ -z "$api_response" ]; then
  echo "Error: Failed to fetch data from API or API returned empty response."
  exit 1
fi

# Define the jq filter
# 1. .data[]: Access each object within the "data" array.
# 2. select(has("top_provider")): Filter out objects that do NOT have the "top_provider" key.
#    This also implicitly filters out objects where top_provider might be null,
#    as `has("key")` checks for key existence, not null value.
# 3. { ... }: For each selected object, construct a new object with the desired keys:
#    - display_name: Mapped from the input "name" field.
#    - name: Mapped from the input "id" field.
#    - max_tokens: Mapped from the input "context_length" field.
#    - max_output_tokens: Mapped from "max_completion_tokens" within the "top_provider" object.
#    - max_completion_tokens: Also mapped from "max_completion_tokens" within "top_provider".
# 4. [ ... ]: Collect all the transformed objects into a single JSON array.
jq_filter='[
  .data[] |
  select(has("top_provider")) |
  {
    display_name: .name,
    name: .id,
    max_tokens: .context_length,
    max_output_tokens: .top_provider.max_completion_tokens,
    max_completion_tokens: .top_provider.max_completion_tokens
  }
] | sort_by(.name)'

# Process the API response with jq and save to the output file
echo "Processing data with jq and saving to $OUTPUT_FILE..."
echo "$api_response" | jq "$jq_filter" > "$OUTPUT_FILE"

# Check if jq processing was successful (output file was created and not empty)
if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
  echo "Successfully processed model data."
  echo "Output saved to $OUTPUT_FILE"
  echo "Number of models processed: $(jq '. | length' "$OUTPUT_FILE")"
elif [ $? -ne 0 ]; then
  echo "Error: jq processing failed."
  # You can uncomment the next line to see the raw API response if jq fails
  # echo "Raw API response was: $api_response"
  exit 1
else
  echo "Warning: jq processing seemed to succeed, but the output file $OUTPUT_FILE is empty."
  echo "This might happen if no models matched the filter criteria (e.g., all lacked 'top_provider')."
fi

exit 0
