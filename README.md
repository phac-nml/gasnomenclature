[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A523.04.3-brightgreen.svg)](https://www.nextflow.io/)

# Genomic Address Service Nomenclature Workflow

This workflow takes provided JSON-formatted MLST allelic profiles and assigns cluster addresses to samples based on an existing cluster designations. This pipeline is designed to be integrated into IRIDA Next. However, it may be run as a stand-alone pipeline.

A brief overview of the usage of this pipeline is given below. Detailed documentation can be found in the [docs/](docs/) directory.

# Input

The input to the pipeline is a standard sample sheet (passed as `--input samplesheet.csv`) that looks like:

| sample  | mlst_alleles      | address |
| ------- | ----------------- | ------- |
| sampleA | sampleA.mlst.json | 1.1.1   |
| sampleQ | sampleQ.mlst.json |         |
| sampleF | sampleF.mlst.json |         |

The structure of this file is defined in [assets/schema_input.json](assets/schema_input.json). Validation of the sample sheet is performed by [nf-validation](https://nextflow-io.github.io/nf-validation/).

Details on the columns can be found in the [Full samplesheet](docs/usage.md#full-samplesheet) documentation.

# Parameters

The main parameters are `--input` as defined above and `--output` for specifying the output results directory. You may wish to provide `-profile singularity` to specify the use of singularity containers and `-r [branch]` to specify which GitHub branch you would like to run.

## Distance Method and Thresholds

Profile_Dists and the Genomic Address Service workflows can use two distance methods: hamming or scaled.

### Hamming Distances

Hamming distances are integers representing the number of differing loci between two sequences and will range between [0, n], where `n` is the total number of loci. When using Hamming distances, you must specify `--pd_distm hamming` and provide Hamming distance thresholds as integers between [0, n]: `--gm_thresholds "10,5,0"` (10, 5, and 0 loci).

### Scaled Distances

Scaled distances are floats representing the percentage of differing loci between two sequences and will range between [0.0, 100.0]. When using scaled distances, you must specify `--pd_distm scaled` and provide percentages between [0.0, 100.0] as thresholds: `--gm_thresholds "50,20,0"` (50%, 20%, and 0% of loci).

### Thresholds and Linkage Methods

The `--gm_thresholds` parameter sets thresholds for each cluster level, which dictate how sequences are assigned cluster codes. These thresholds specify the maximum allowable differences in loci between sequences sharing the same cluster code at each level. The consistency of these thresholds in ensuring uniform cluster codes across levels depends on the `--gm_method` parameter, which determines the linkage method used for clustering.

- _Complete Linkage_: When using complete linkage clustering, sequences are grouped such that identical cluster codes at a particular level guarantee that all sequences in that cluster are within the specified threshold distance. For example, specifying `--pd_distm hamming` and `--gm_thresholds "10,5,0"` would mean that sequences with no more than 10 loci differences are assigned the same cluster code at the first level, no more than 5 differences at the second level, and identical sequences at the third level.

- _Average Linkage_: With average linkage clustering, sequences may share the same cluster code if their average distance is below the specified threshold. For instance, sequences with average distances less than 10, 5, and 0 for each level respectively may share the same cluster code.

- _Single Linkage_: Single linkage clustering can result in merging distant samples into the same cluster if there exists a third sample that bridges the distance between them. This method does not provide strict guarantees on the maximum distance within a cluster, potentially allowing distant sequences to share the same cluster code.

## Profile_dists

The following can be used to adjust parameters for the [profile_dists][] tool.

- `--pd_distm`: The distance method/unit, either _hamming_ or _scaled_. For _hamming_ distances, the distance values will be a non-negative integer. For _scaled_ distances, the distance values are between 0.0 and 100.0. Please see the [Distance Method and Thresholds](#distance-method-and-thresholds) section for more information.
- `--pd_missing_threshold`: The maximum proportion of missing data per locus for a locus to be kept in the analysis. Values from 0 to 1.
- `--pd_sample_quality_threshold`: The maximum proportion of missing data per sample for a sample to be kept in the analysis. Values from 0 to 1.
- `--pd_file_type`: Output format file type. One of _text_ or _parquet_.
- `--pd_mapping_file`: A file used to map allele codes to integers for internal distance calculations. This is the same file as produced from the _profile dists_ step (the [allele_map.json](docs/output.md#profile-dists) file). Normally, this is unneeded unless you wish to override the automated process of mapping alleles to integers.
- `--pd_skip`: Skip QA/QC steps. Can be used as a flag, `--pd_skip`, or passing a boolean, `--pd_skip true` or `--pd_skip false`.
- `--pd_columns`: Path to a file that defines the loci to keep within the analysis (default when unset is to keep all loci). Formatted as a single column file with one locus name per line. For example:
  - **Single column format**
    ```
    loci1
    loci2
    loci3
    ```
- `--pd_count_missing`: Count missing alleles as different. Can be used as a flag, `--pd_count_missing`, or passing a boolean, `--pd_count_missing true` or `--pd_count_missing false`. If true, will consider missing allele calls for the same locus between samples as a difference, increasing the distance counts.

## GAS CALL

The following can be used to adjust parameters for the [gas call][] tool.

- `--gm_thresholds`: Thresholds delimited by `,`. Values should match units from `--pd_distm` (either _hamming_ or _scaled_). Please see the [Distance Method and Thresholds](#distance-method-and-thresholds) section for more information.
- `--gm_method`: The linkage method to use for clustering. Value should be one of _single_, _average_, or _complete_.
- `--gm_delimiter`: Delimiter desired for nomenclature code. Must be alphanumeric or one of `._-`.

## Optional Profile and Cluster Address Databases (as used by IRIDA-Next)

In addition to the reference samples included in the input samplesheet (which already contain pre-computed cluster addresses), users can incorporate additional pre-computed reference profiles and cluster addresses by providing them as parameterized databases.
Note that any address levels present in the additional databases but absent from the input samplesheet addresses will be disregarded.

- `--db_profiles`: Specifies the path to the database containing pre-merged MLST profiles in tab-separated format. To ensure compatibility, the database structure must adhere to the expected header format corresponding to the samples included in the input samplesheet:

| sample_id | l1  | l2  | ... | ln  |
| --------- | --- | --- | --- | --- |
| sampleA   | 1   | 1   | ... | 1   |
| sampleB   | 1   | 1   | ... | 2   |
| sampleC   | 2   | 1   | ... | 1   |

- `--db_clusters`: Specifies the path to the database containing cluster addresses for additional samples in tab-separated format. To ensure compatibility, the database structure must adhere to the expected header format corresponding to the samples included in the input samplesheet:

| id      | address | level_1 | level_2 | ... | level_n |
| ------- | ------- | ------- | ------- | --- | ------- |
| sampleA | 1.1.1   | 1       | 1       | ... | 1       |
| sampleB | 1.1.2   | 1       | 1       | ... | 2       |
| sampleC | 2.1.1   | 2       | 1       | ... | 1       |

_Note: To add additional reference samples to the pipeline, both `--db_profiles` and `--db_clusters` must be provided together, and all `sample_id`'s in `--db_profiles` must match the `id`'s in `--db_clusters`_

## Other

Other parameters (defaults from nf-core) are defined in [nextflow_schema.json](nextflow_schmea.json).

# Running

To run the pipeline, please do:

```bash
nextflow run phac-nml/gasnomenclature -profile singularity -r main -latest --input assets/samplesheet.csv --outdir results
```

Where the `samplesheet.csv` is structured as specified in the [Input](#input) section.

# Output

A JSON file for loading metadata into IRIDA Next is output by this pipeline. The format of this JSON file is specified in our [Pipeline Standards for the IRIDA Next JSON](https://github.com/phac-nml/pipeline-standards#32-irida-next-json). This JSON file is written directly within the `--outdir` provided to the pipeline with the name `iridanext.output.json.gz` (ex: `[outdir]/iridanext.output.json.gz`).

An example of the what the contents of the IRIDA Next JSON file looks like for this particular pipeline is as follows:

```
{
    "files": {
        "global": [],
        "samples": {
            "sampleF": [
                {
                    "path": "input/sampleF_error_report.csv"
                }
            ],
        }
    },
    "metadata": {
        "samples": {
            "sampleQ": {
                "address": "1.1.3",
            }
        }
    }
}
```

Within the `files` section of this JSON file, all of the output paths are relative to the `outdir`. Therefore, `"path": "input/sampleF_error_report.csv"` refers to a file located within `outdir/input/sampleF_error_report.csv`. This file is generated only if a sample fails the input check during samplesheet assessment.

## Test profile

To run with the test profile, please do:

```bash
nextflow run phac-nml/gasnomenclature -profile docker,test -r main -latest --outdir results
```

# Legal

Copyright 2024 Government of Canada

Licensed under the MIT License (the "License"); you may not use
this work except in compliance with the License. You may obtain a copy of the
License at:

https://opensource.org/license/mit/

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
