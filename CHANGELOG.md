# phac-nml/gasnomenclature: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.2] - 2025/11/17

### `Updated`

- Updated `profile_dists` dependency to version `1.0.10` and `genomic_address_service` to `0.3.0`. [PR #86](https://github.com/phac-nml/gasnomenclature/pull/86)
- Adding GitHub CI tests against Nextflow `24.10.3`. [PR #85](https://github.com/phac-nml/gasnomenclature/pull/85)

## [0.8.1] - 2025/09/05

### `Updated`

- `PREPROCESS_REFERENCES` csvtk container updated to `0.31.0` for which `csvtk cut` has a `-m` `--allow-missing-col` missing column flag. [PR #83](https://github.com/phac-nml/gasnomenclature/pull/83)

### `Added`

- Added a process level `nf-test` for `LOCIDEX_MERGE` to confirm backward compatibility between MLST JSON files with and without a `"manfiest"` key. [PR #83](https://github.com/phac-nml/gasnomenclature/pull/83)

## [0.8.0] - 2025/08/29

### `Added`

**Reduce the Number of Loci used in Analysis**

- Update the `PREPROCESS_REFERENCES` process to use only the selected loci specified by the `--pd_columns` parameter. [PR #80](https://github.com/phac-nml/gasnomenclature/pull/80)
- Update the `LOCIDEX_MERGE` process to include only the selected loci specified by the `--pd_columns` parameter in the `profile.tsv` file. [PR #81](https://github.com/phac-nml/gasnomenclature/pull/81)
  - Updated `locidex` version to [v.0.4.0](https://github.com/phac-nml/locidex/releases/tag/v0.4.0) which adds a `--loci` parameter to input select loci for included in `profile.tsv`. [PR #81](https://github.com/phac-nml/gasnomenclature/pull/81)
- Add parameter `--skip_reduce_loci` to skip reducing loci. [PR #80](https://github.com/phac-nml/gasnomenclature/pull/80)

## [0.7.2] - 2025/08/06

### `Modified`

- Parameter logic for `PROFILE_DISTS` was changed to only use `--pd_max_cpus` if it is below the `task.cpus`. [PR #78](https://github.com/phac-nml/gasnomenclature/pull/78)
- Remove `--max_mem` in favor of `--batch_size`. [PR #78](https://github.com/phac-nml/gasnomenclature/pull/78)

## [0.7.1] - 2025/08/05

### `Bug Fix`

- Fix the bug that is caused by clusters not matching profiles [issue #75](https://github.com/phac-nml/gasnomenclature/issues/75). [PR #76](https://github.com/phac-nml/gasnomenclature/pull/76)

## [0.7.0] - 2025/07/31

### `Added`

- Added a `PREPROCESS_PROFILES` process that adds a `@` prefix to the `--db_profiles` `sample_id` to force unique identifiers for samples (required for `profile_dists`). If reference/background profiles are already unique process can be overriden with `--skip_prefix_background_profiles true`. [PR #72](https://github.com/phac-nml/gasnomenclature/pull/72)
- Made to new `profile_dists` parameters available to nextflow pipeline `--pd_max_cpus` and `--pd_max_batch_size`. [PR #73](https://github.com/phac-nml/gasnomenclature/pull/73)

### `Modified`

- `APPEND_PROFILES` no longer renames `sample_id` with duplicate to prevent conflicts for `profile_dists`, user should keep the default `--skip_prefix_background_profiles` unless they know that there is no duplicates. [PR #72](https://github.com/phac-nml/gasnomenclature/pull/72)
- Moved the setting of non-filepath parameters for `PROFILE_DISTS` to the `config/modules.config`. [PR #73](https://github.com/phac-nml/gasnomenclature/pull/73)

## [0.6.3] - 2025/07/11

### `Fix`

- Fixed issue with `csvtk cat | csvtk sort` failing in `APPEND_PROFILES` step when working with large amounts of data. [PR #70](https://github.com/phac-nml/gasnomenclature/pull/70)

## [0.6.2] - 2025/06/13

### `Updated`

- Update `profile_dists` to `v.1.0.8`. [PR #68](https://github.com/phac-nml/gasnomenclature/pull/68)
- Updated nf-core linting and some of the nf-core GitHub actions to the latest versions. [PR #68](https://github.com/phac-nml/gasnomenclature/pull/68)
- Updated nf-core module [custom_dumpsoftwareversions](https://nf-co.re/modules/custom_dumpsoftwareversions/) to latest version (commit `05954dab2ff481bcb999f24455da29a5828af08d`). [PR #68](https://github.com/phac-nml/gasnomenclature/pull/68)

### `Added`

- Added an ubuntu container for the `COPY_FILE` process to ensure bash commands are functional. [PR #68](https://github.com/phac-nml/gasnomenclature/pull/68)

## [0.6.1] - 2025/05/26

### `Fix`

- Fix Issue [#64](https://github.com/phac-nml/gasnomenclature/issues/64) by providing a new process `copyFile` to rename duplicate MLST files. [PR #63](https://github.com/phac-nml/gasnomenclature/pull/63)
- Fix Issue [#63](https://github.com/phac-nml/gasnomenclature/issues/63) changing input type for `merge_tsv`. [PR #63](https://github.com/phac-nml/gasnomenclature/pull/63)

### `Updated`

- Update `profile_dists` to `v.1.0.6`. [PR #63](https://github.com/phac-nml/gasnomenclature/pull/63)

## [0.6.0] - 2025/05/12

### `Updated`

- Updated profile_dists to version 1.0.5. [PR #59](https://github.com/phac-nml/gasnomenclature/pull/59)
- Updated genomic_address_service to version 0.2.0. [PR #59](https://github.com/phac-nml/gasnomenclature/pull/59)
- Added software_versions.yml to pipeline output. [PR #59](https://github.com/phac-nml/gasnomenclature/pull/59)

### `Fix`

- A bug where addresses weren't called when no samples in the input sample sheet had addressess already assigned. [PR #60](https://github.com/phac-nml/gasnomenclature/pull/60)
- A bug where large gzipped files would cause pipe errors (141) and then the `append_profiles` process would fail. This would cause the whole pipeline to fail. A fix has been added to prevent this failure from failing the process. [PR #61](https://github.com/phac-nml/gasnomenclature/pull/61)
- Fixed issue [#57](https://github.com/phac-nml/gasnomenclature/issues/57), where `LOCIDEX_MERGE` had file collisions in pubDir due to multiple processes generating the same file name (when split into multiple batches). [PR #58](https://github.com/phac-nml/gasnomenclature/pull/58)

## [0.5.1] - 2025/05/01

### `Updated`

- Increased resources from `process_single` to `process_high` for `APPEND_PROFILES` step in order to handle very large collections of background profiles. [PR #55](https://github.com/phac-nml/gasnomenclature/pull/55).

### `Fix`

- Query samples now put into batches for `LOCIDEX_MERGE` fixing the issue [#52](https://github.com/phac-nml/gasnomenclature/issues/52). [PR #53](https://github.com/phac-nml/gasnomenclature/pull/53)

## [0.5.0] - 2025/04/02

### `Updated`

- Update the `locidex` version to [0.3.0](https://pypi.org/project/locidex/0.3.0/). `locidex merge` has integrated the functionality of module `input_assure`. [PR 45](https://github.com/phac-nml/gasnomenclature/pull/45)
- Update the `genomic address service` version to [0.1.5](https://github.com/phac-nml/genomic_address_service/releases/tag/0.1.5). Changes how multiple samples without address are assigned addresses when belonging to the same cluster. [PR 47](https://github.com/phac-nml/gasnomenclature/pull/47) [PR 48](https://github.com/phac-nml/gasnomenclature/pull/47)
- Update the `profile_dist` version to [1.0.4](https://github.com/phac-nml/profile_dists/releases/tag/1.0.4). [PR 50](https://github.com/phac-nml/gasnomenclature/pull/50)

### `Enhancement`

- `locidex merge` in `0.3.0` now performs the functionality of `input_assure` (checking sample name against MLST profiles). This allows `gasnomenclature` to remove `input_assure` so that the MLST JSON file is read only once, and no longer needs to re-write with correction. [PR 45](https://github.com/phac-nml/gasnomenclature/pull/45)

### `Changes`

- The output from `locidex merge` now includes a `MLST_error_report.csv` similar to that of `input_assure` (this file is also passed to `concat`). [PR 45](https://github.com/phac-nml/gasnomenclature/pull/45)
- The input/output for `gasnomenclature` "address" has been changed to "genomic_address_name". [PR 48](https://github.com/phac-nml/gasnomenclature/pull/48)
- Modified the UI for running the pipeline in IRIDA-Next web interface. [PR 50](https://github.com/phac-nml/gasnomenclature/pull/50)

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
[0.5.0]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.5.0
[0.5.1]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.5.1
[0.6.0]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.6.0
[0.6.1]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.6.1
[0.6.2]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.6.2
[0.6.3]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.6.3
[0.7.0]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.7.0
[0.7.1]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.7.1
[0.7.2]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.7.2
[0.8.0]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.8.0
[0.8.1]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.8.1
[0.8.1]: https://github.com/phac-nml/gasnomenclature/releases/tag/0.8.2
