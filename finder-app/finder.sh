#!/bin/bash

# Check if the required arguments are provided
if [ $# -ne 2 ]; then
  echo "Error: Two arguments required. Usage: $0 <filesdir> <searchstr>"
  exit 1
fi

# Assign arguments to variables
filesdir=$1
searchstr=$2

# Check if filesdir is a directory
if [ ! -d "$filesdir" ]; then
  echo "Error: $filesdir is not a directory or does not exist."
  exit 1
fi

# Count the number of files in the directory and its subdirectories
num_files=$(find "$filesdir" -type f | wc -l)

# Count the number of matching lines
num_matches=$(grep -r "$searchstr" "$filesdir" 2>/dev/null | wc -l)

# Print the results
echo "The number of files are $num_files and the number of matching lines are $num_matches"

exit 0
