#!/bin/bash

# Check if the required arguments are provided
if [ $# -ne 2 ]; then
  echo "Error: Two arguments required. Usage: $0 <writefile> <writestr>"
  exit 1
fi

# Assign arguments to variables
writefile=$1
writestr=$2

# Extract the directory path from writefile
dirname=$(dirname "$writefile")

# Create the directory if it does not exist
if [ ! -d "$dirname" ]; then
  mkdir -p "$dirname"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create directory $dirname."
    exit 1
  fi
fi

# Create or overwrite the file with writestr
echo "$writestr" > "$writefile"
if [ $? -ne 0 ]; then
  echo "Error: Failed to write to file $writefile."
  exit 1
fi

# Success message
echo "File $writefile created with content: $writestr"

exit 0
