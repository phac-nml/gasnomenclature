# phac-nml/gasnomenclature: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025/03/03

### `Enhancement`

## LOCIDEX

- Added a pre-processing step to the input of `LOCIDEX_MERGE` that splits-up samples, into batches (default batch size: `100`), to allow for `LOCIDEX_MERGE` to be run in parallel. To modify the size of batches use the parameter `--batch_size n`

### `Updated`

- The container for docker/singularity for `Profile_Dist` was changed to quay.io/biocontainer build 1.0.3 (this profile_dists version was just to fix the PYPI build recipe which caused the container to not be built) which has no changes from 1.0.2

## [0.3.1] - 2025/02/11

### `Fixed`

- Addressed the pipefail Issue [#36](https://github.com/phac-nml/gasnomenclature/issues/36) when large sample sizes are passed to `APPEND_CLUSTERS()` in [PR #37](https://github.com/phac-nml/gasnomenclature/pull/37) by replacing a pipe with a temporary intermediate file.
- Updated GAS to version [0.1.4](https://github.com/phac-nml/genomic_address_service/releases/tag/0.1.4) which resolves Issue [#38](https://github.com/phac-nml/gasnomenclature/issues/38) and [#33](https://github.com/phac-nml/gasnomenclature/issues/33) which now allows `linkage.method` parameters of `gasnomenclature` to be passed to `GAS call`.

## [0.3.0] - 2025/01/09

### `Added`

- Enhanced the pipeline to integrate _optional_ user-provided reference profiles and cluster addresses for additional samples [PR #29](https://github.com/phac-nml/gasnomenclature/pull/29):
  - Added support for `--db_profiles` via the `APPEND_PROFILES` process
  - Added support for `--db_clusters` via the `APPEND_CLUSTERS` process
- Added tests to verify the additional databases can be incorporated and that both databases are required together for their respective processes.

- Added the ability to include a `sample_name` column in the input samplesheet.csv. Allows for compatibility with IRIDA-Next input configuration [PR #30](https://github.com/phac-nml/gasnomenclature/pull/30):
  - `sample_name` special characters will be replaced with `"_"`
  - If no `sample_name` is supplied in the column `sample` will be used
  - To avoid repeat values for `sample_name` all `sample_name` values will be suffixed with the unique `sample` value from the input file
- Updated `gas/call` to version `0.1.2` and both `CLUSTER_FILE` and `APPEND_CLUSTERS` to comply with the latest formatting requirements.

### `Changed`

- Genomic Service Address version [0.1.1](https://pypi.org/project/genomic-address-service/0.1.1/) -> [0.1.3](https://pypi.org/project/genomic-address-service/0.1.3/)

- Refined the format of `reference_cluster.tsv (rclusters)` used by `GAS CALL` to require only `id` and `address` columns. This change involved updates to both the `append_clusters` and `cluster_file` modules.

## [0.2.3] - 2024/09/25

### `Changed`

- Updated `FILTER_QUERY` process to treat `query_ids` as a file input (path instead of val) for proper file path handling across environments [PR27](https://github.com/phac-nml/gasnomenclature/pull/27)
- Addressed [Issue26](https://github.com/phac-nml/gasnomenclature/issues/26)

## [0.2.2] - 2024/09/13

### `Changed`

- Updated FILTER_QUERY to process query IDs from a file rather than passing them as a string, preventing errors caused by long argument strings [PR24](https://github.com/phac-nml/gasnomenclature/pull/24)

## [0.2.1] - 2024/09/10

### `Changed`

- Upgraded `profile_dists` to version `1.0.2` in the container closure

## [0.2.0] - 2024/09/05

### `Changed`

- Upgraded `locidex/merge` to version `0.2.3` and updated `input_assure.py` and test data for compatibility with the new `mlst.json` allele file format [PR20](https://github.com/phac-nml/gasnomenclature/pull/20)
- Removed `quay.io` docker repository tags from modules [PR19](https://github.com/phac-nml/gasnomenclature/pull/19)

This pipeline is now compatible only with output generated by [Locidex v0.2.3+](https://github.com/phac-nml/locidex) and [Mikrokondo v0.4.0+](https://github.com/phac-nml/mikrokondo/releases/tag/v0.4.0).

## [0.1.0] - 2024/06/28

Initial release of the Genomic Address Nomenclature pipeline to be used to assign cluster addresses to samples based on an existing cluster designations.

### `Added`

- Input of cg/wgMLST allele calls produced from [locidex](https://github.com/phac-nml/locidex).
- Output of assigned cluster addresses for any **query** samples using [profile_dists](https://github.com/phac-nml/profile_dists) and [gas call](https://github.com/phac-nml/genomic_address_service).

[0.1.0]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.1.0
[0.2.0]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.2.0
[0.2.1]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.2.1
[0.2.2]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.2.2
[0.2.3]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.2.3
[0.3.0]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.3.0
[0.3.1]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.3.1
[0.4.0]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.4.0
