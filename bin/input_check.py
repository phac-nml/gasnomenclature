#!/usr/bin/env python

import json
import argparse
import sys
import csv


def check_inputs(json_file, sample_id, address, output_match_file, output_error_file):
    # Define a variable to store the match_status (True or False)
    with open(json_file, 'r') as f:
        json_data = json.load(f)
    match_status = sample_id in json_data

    # Write match status to file
    with open(output_match_file, "w") as f:
        f.write(str(match_status))

    # Define error message based on meta.address (query or reference)
    if address == "null":
        error_message = f"Query {sample_id} removed from pipeline"
    else:
        error_message = f"Pipeline stopped: Reference {sample_id}'s input ID and MLST JSON file key DO NOT MATCH"

    # Write sample ID and JSON key to error report CSV if not matched; include error message
    if not match_status:
        with open(output_error_file, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["sample", "JSON_key", "error_message"])
            writer.writerow([sample_id, list(json_data.keys())[0], error_message])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check sample inputs and generate an error report.")
    parser.add_argument("--input", help="Path to the mlst.json file.", required=True)
    parser.add_argument("--sample_id", help="Sample ID to check in the JSON file.", required=True)
    parser.add_argument("--address", help="Address to use in the error message.", required=True)
    parser.add_argument("--output_error", help="Path to the error report file.", required=True)
    parser.add_argument("--output_match", help="Path to the match status file.", required=True)
    
    args = parser.parse_args()

    check_inputs(args.input, args.sample_id, args.address, args.output_match, args.output_error)
