#!/bin/bash

# Function to check if a directory is empty (recursively) and delete contents if not empty
check_directory_empty_and_delete() {
    dir=$1

    if [ -d "$dir" ]; then
        # Check if the directory has any files or folders inside (including subdirectories)
        if [ -z "$(find "$dir" -mindepth 1 -print -quit)" ]; then
            echo "$(basename "$dir")                                    yes"
            return 0  # Empty
        else
            # If the directory is not empty, delete all its contents
            echo "$(basename "$dir")                                    no"
            echo "Deleting contents of directory: $dir"
            rm -rf "$dir"/*  # This will delete all files and subdirectories inside
            echo "Contents of $dir deleted."
            return 1  # Not empty
        fi
    else
        echo "$dir is not a valid directory."
        return 2  # Error
    fi
}

# Function to check if directory name is numeric (contains only numbers)
delete_if_numeric_directory() {
    dir=$1

    dir_name=$(basename "$dir")

    # Check if the directory name is numeric (only numbers)
    if [[ "$dir_name" =~ ^[0-9]+$ ]]; then
        echo "Deleting numeric directory: $dir"
        rm -rf "$dir"  # Delete the numeric directory and its contents
        echo "Numeric directory $dir deleted."
    fi
}

# Check if the script is being run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "This script should be run with sudo. Please try again with 'sudo'."
    exit 1
fi

# Check if the user provided a directory path
if [ $# -eq 0 ]; then
    echo "Please provide a directory path as an argument."
    exit 1
fi

# Get the directory path from the argument
directory_path=$1

# Print directory provided
echo "Directory Provided: $directory_path"

# List the sub-directories (non-recursive)
subdirs=$(find "$directory_path" -mindepth 1 -maxdepth 1 -type d)
subdir_count=$(echo "$subdirs" | wc -l)

# Print the sub-directories count and start processing
echo "Sub-Directories Found: $subdir_count"
echo "Processing Sub-directories:"

# Initialize counters for empty and non-empty directories
empty_count=0
non_empty_count=0
current_count=1

# Print the header for the table
printf "\n%-40s %-15s\n" "Directory Name" "Empty_Status"
echo "--------------------------------------------------------------"

# Loop over the subdirectories and check their empty status
for subdir in $subdirs; do
    # Extract only the directory name from the path (removing the full path)
    dir_name=$(basename "$subdir")

    # Check and delete the directory if its name is numeric
    delete_if_numeric_directory "$subdir"

    # Use printf to ensure proper padding for alignment
    formatted_dir_name=$(printf "%-40s" "$dir_name")

    # Check and print the empty status for each directory
    if check_directory_empty_and_delete "$subdir"; then
        ((empty_count++))
    else
        ((non_empty_count++))
    fi

    # Print progress status
    echo -ne "Progress: $current_count/$subdir_count processed\r"

    # Increment the counter for progress
    ((current_count++))
done

# Print summary
echo "--------------------------------------------------------------"
echo "Total Empty Directory(ies): $empty_count"
echo "Total Non-Empty Directory(ies): $non_empty_count"
echo "--------------------------------------------------------------"

# Calculate and print the script execution time
start_time=$(date +%s)
end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "Script Executed in $execution_time sec"
