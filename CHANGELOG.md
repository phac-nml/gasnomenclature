# phac-nml/gasnomenclature: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## In-development

## 1.0.5 - 2024/06/17

- Updated modules to include:

  - `input_assure`: Performs a validation check on the samplesheet inputs to ensure that the sampleID precisely matches the MLST JSON key and enforces necessary changes where discrepancies are found.
  - `cluster_file`: Generates the expected_clusters.txt file from reference sample addresses for use in GAS_call.
  - `filter_query`: Filters and generates a csv file containing only the cluster addresses for query samples.

- Pinned nf-iridanext plugin
- Added tests for the full pipeline, independant modules, and input parameters
- Updated documentation and configuration files

## 1.0.3 - 2024/02/23

- Pinned nf-validation@1.1.3 plugin

## 1.0.2 - 2023/12/18

- Removed GitHub workflows that weren't needed.
- Adding additional parameters for testing purposes.

## 1.0.1 - 2023/12/06

Allowing non-gzipped FASTQ files as input. Default branch is now main.

## 1.0.0 - 2023/11/30

Initial release of phac-nml/gasnomenclature, created with the [nf-core](https://nf-co.re/) template.

### `Added`

### `Fixed`

### `Dependencies`

### `Deprecated`
