#!/bin/bash

# Base URL
BASE_URL="http://darkly.prj/.hidden/"

# Output directory
OUTPUT_DIR="./downloaded_readmes"
mkdir -p "$OUTPUT_DIR"

# Function to download README files recursively
download_readmes() {
    local current_url="$1"
    local current_path="$2"
    
    echo "Scanning: $current_url"
    
    # Download the directory listing
    local temp_file=$(mktemp)
    if ! curl -s -f "$current_url" > "$temp_file"; then
        echo "Failed to download: $current_url"
        rm -f "$temp_file"
        return
    fi
    
    # Extract all links from the HTML (href attributes)
    local links=()
    while IFS= read -r line; do
        # Extract href values, skip ../ and absolute URLs
        if [[ $line =~ href=\"([^\"]+)\" ]]; then
            local link="${BASH_REMATCH[1]}"
            if [[ "$link" != "../" && "$link" != "http"* && "$link" != "mailto:"* ]]; then
                links+=("$link")
            fi
        fi
    done < "$temp_file"
    
    rm -f "$temp_file"
    
    # Process each link
    for link in "${links[@]}"; do
        local full_url="${current_url}${link}"
        local full_path="${current_path}${link}"
        
        # If it's a README file, download it
        if [[ "$link" == *"README"* ]]; then
            echo "Downloading: $full_url"
            local output_file="${OUTPUT_DIR}${full_path}"
            mkdir -p "$(dirname "$output_file")"
            if curl -s -f "$full_url" -o "$output_file"; then
                echo "Saved: $output_file"
                echo "Content:"
                cat "$output_file"
                echo "----------------------------------------"
            else
                echo "Failed to download: $full_url"
            fi
        # If it's a directory (ends with /), recurse into it
        elif [[ "$link" == */ ]]; then
            download_readmes "$full_url" "$full_path"
        fi
    done
}

# Start the recursive download
echo "Starting download of all README files from $BASE_URL"
download_readmes "$BASE_URL" "/"

echo "Download completed. All files saved in: $OUTPUT_DIR"

