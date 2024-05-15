#!/usr/bin/env python

import json
import argparse
import csv


def check_inputs(json_file, sample_id, address, output_file):
    # Define a variable to store the match_status (True or False)
    json_data = json.load(open(json_file))
    match_status = sample_id in json.load(open(json_file))

    # Define error message based on address (query or reference)
    if address == "null":
        error_message = f"Query {sample_id} removed from pipeline"
    else:
        error_message = f"Pipeline stopped: Reference {sample_id}'s input ID and MLST JSON file key DO NOT MATCH"

    # Write match status to error report CSV
    if not match_status:
        with open(output_file, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["sample", "JSON_key", "error_message"])
            writer.writerow([sample_id, list(json_data.keys())[0], error_message])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check sample inputs")
    parser.add_argument("--input", help="Missing mlst.json file path", required=True)
    parser.add_argument(
        "--sample_id", help="Missing sample meta.id path", required=True
    )
    parser.add_argument(
        "--address", help="Missing sample meta.address path", required=True
    )
    parser.add_argument(
        "--output", help="Requires an error report file path", required=True
    )
    args = parser.parse_args()

    check_inputs(args.input, args.sample_id, args.address, args.output)
