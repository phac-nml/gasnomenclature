#!/usr/bin/env python

import json
import argparse
import sys
import csv
import gzip

def open_file(file_path, mode):
    # Open a file based on the file extension
    if file_path.endswith('.gz'):
        return gzip.open(file_path, mode)
    else:
        return open(file_path, mode)

def check_inputs(json_file, sample_id, address, output_error_file):
    # Define a variable to store the match_status (True or False)
    with open(json_file, "rt") as f:
        json_data = json.load(f)
    match_status = sample_id in json_data

    # Define the original key in the JSON data
    original_key = list(json_data.keys())[0]

    # Define error message based on meta.address (query or reference)
    if address == "null":
        error_message = f"Query {sample_id} ID and JSON key in {json_file} DO NOT MATCH. The '{original_key}' key in {json_file} has been forcefully changed to '{sample_id}': User should manually check input files to ensure correctness."
    else:
        error_message = f"Reference {sample_id} ID and JSON key in {json_file} DO NOT MATCH. The '{original_key}' key in {json_file} has been forcefully changed to '{sample_id}': User should manually check input files to ensure correctness."

    # Write sample ID and JSON key to error report CSV if not matched; include error message
    if not match_status:
        with open(output_error_file, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["sample", "JSON_key", "error_message"])
            writer.writerow([sample_id, original_key, error_message])

    # Update the JSON file with the new sample ID
        json_data[sample_id] = json_data.pop(original_key)
        with open(json_file, "wt") as f:
            json.dump(json_data, f, indent=4)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Check sample inputs, force change if ID ≠ KEY, and generate an error report."
    )
    parser.add_argument("--input", help="Path to the mlst.json file.", required=True)
    parser.add_argument(
        "--sample_id", help="Sample ID to check in the JSON file.", required=True
    )
    parser.add_argument(
        "--address", help="Address to use in the error message.", required=True
    )
    parser.add_argument(
        "--output_error", help="Path to the error report file.", required=True
    )

    args = parser.parse_args()

    check_inputs(
        args.input, args.sample_id, args.address, args.output_error
    )
