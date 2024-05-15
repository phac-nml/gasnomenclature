#!/usr/bin/env python

import json
import argparse
import sys


def check_inputs(json_file, sample_id, output_file):
    # Define a variable to store the match status
    match_status = sample_id in json.load(open(json_file))

    # Write match status to file
    with open(output_file, "w") as f:
        f.write(str(match_status))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check sample inputs")
    parser.add_argument("--input", help="Missing mlst.json file path", required=True)
    parser.add_argument(
        "--sample_id", help="Missing sample meta.id path", required=True
    )
    parser.add_argument(
        "--output", help="Missing match_status file path", required=True
    )
    args = parser.parse_args()

    check_inputs(args.input, args.sample_id, args.output)
