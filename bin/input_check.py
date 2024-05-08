#!/usr/bin/env python

import json
import argparse
import csv


def check_inputs(json_file, sample_id, output_file):
    # Define a variable to store the match status
    json_data = json.load(open(json_file))
    match_status = sample_id in json_data

    # Write match status to error report CSV
    if not match_status:
        with open(output_file, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["sample", "Sample ID matches MLST.JSON key?"])
            writer.writerow([sample_id, match_status])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check sample inputs")
    parser.add_argument("--input", help="Missing mlst.json file path", required=True)
    parser.add_argument(
        "--sample_id", help="Missing sample meta.id path", required=True
    )
    parser.add_argument(
        "--output", help="Requires an error report file path", required=True
    )
    args = parser.parse_args()

    check_inputs(args.input, args.sample_id, args.output)
