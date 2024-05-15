#!/usr/bin/env python

import argparse
import json
import os
import sys


def process_input(id, address, id_match, input_file, output_file):
    try:
        # Load JSON data from input file
        with open(input_file, "r") as json_file:
            data = json.load(json_file)

        if id_match == "True":
            print("ID match is True. Outputting the same tuple.", file=sys.stdout)
            with open(output_file, "w") as output:
                json.dump(data, output)
        elif address == "null" and id_match == "False":
            print("Query sample removed from analysis.", file=sys.stdout)
            # Remove the input file to indicate this sample should be excluded
            os.remove(input_file)
        elif id_match == "False":
            print(
                "Pipeline stopped: Reference sample ID and MLST JSON file key DO NOT MATCH.",
                file=sys.stderr,
            )
            sys.exit(1)
        else:
            print("Unhandled case in input conditions.", file=sys.stderr)
            sys.exit(1)
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process input tuple.")
    parser.add_argument("--id", type=str, required=True, help="Sample ID")
    parser.add_argument("--address", type=str, required=True, help="Cluster Address")
    parser.add_argument("--id_match", type=str, required=True, help="ID Match Boolean")
    parser.add_argument(
        "--input", type=str, required=True, help="Path to the input JSON file"
    )
    parser.add_argument(
        "--output", type=str, required=True, help="Path to the output file"
    )

    args = parser.parse_args()

    # Process input
    process_input(args.id, args.address, args.id_match, args.input, args.output)
