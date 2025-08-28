/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet  } from 'plugin/nf-validation'
include { loadIridaSampleIds                                   } from 'plugin/nf-iridanext'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//

include { WRITE_METADATA                         } from "../modules/local/write/main"
include { COPY_FILE                              } from "../modules/local/copyFile/main"
include { LOCIDEX_MERGE as LOCIDEX_MERGE_REF     } from "../modules/local/locidex/merge/main"
include { LOCIDEX_MERGE as LOCIDEX_MERGE_QUERY   } from "../modules/local/locidex/merge/main"
include { LOCIDEX_CONCAT as LOCIDEX_CONCAT_QUERY } from "../modules/local/locidex/concat/main"
include { LOCIDEX_CONCAT as LOCIDEX_CONCAT_REF   } from "../modules/local/locidex/concat/main"
include { PREPROCESS_REFERENCES                  } from "../modules/local/preprocess_references/main"
include { APPEND_PROFILES                        } from "../modules/local/append_profiles/main"
include { PROFILE_DISTS                          } from "../modules/local/profile_dists/main"
include { CLUSTER_FILE                           } from "../modules/local/cluster_file/main"
include { APPEND_CLUSTERS                        } from "../modules/local/append_clusters/main"
include { GAS_CALL                               } from "../modules/local/gas/call/main"
include { FILTER_QUERY                           } from "../modules/local/filter_query/main"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


def prepareFilePath(String filep, GString debug_msg){
    // Rerturns null if a file is not valid
    def return_path = null
    if(filep){
        file_in = file(filep)
        if(file_in.exists()){
            return_path = file_in
            log.debug debug_msg
        }
    }else{
        return_path = []
    }

    return return_path // empty value if file argument is null
}


workflow GAS_NOMENCLATURE {

    ch_versions = Channel.empty()

    // Track processed IDs and MLST files
    def processedIDs  = [] as Set
    def processedMLST  = [] as Set

    // Create a new channel of metadata from a sample sheet
    // NB: `input` corresponds to `params.input` and associated sample sheet schema
    pre_input = Channel.fromSamplesheet("input")
    // and remove non-alphanumeric characters in sample_names (meta.id), whilst also correcting for duplicate sample_names (meta.id)
    .map { meta, mlst_file ->
            uniqueMLST = true
            if (!meta.id) {
                meta.id = meta.irida_id
            } else {
                // Non-alphanumeric characters (excluding _,-,.) will be replaced with "_"
                meta.id = meta.id.replaceAll(/[^A-Za-z0-9_.\-]/, '_')
            }
            // Ensure ID is unique by appending meta.irida_id if needed
            while (processedIDs.contains(meta.id)) {
                meta.id = "${meta.id}_${meta.irida_id}"
            }
            // Check if the MLST file is unique
            if (processedMLST.contains(mlst_file.baseName)) {
                uniqueMLST = false
            }
            // Add the ID to the set of processed IDs
            processedIDs << meta.id
            processedMLST << mlst_file.baseName
            tuple(meta, mlst_file, uniqueMLST)}.loadIridaSampleIds()

    // For the MLST files that are not unique, rename them
    pre_input
        .branch { meta, mlst_file, uniqueMLST ->
            keep: uniqueMLST == true // Keep the unique MLST files as is
            replace: uniqueMLST == false // Rename the non-unique MLST files to avoid collisions
        }.set {mlst_file_rename}
    renamed_input = COPY_FILE(mlst_file_rename.replace)
    unchanged_input = mlst_file_rename.keep
        .map { meta, mlst_file, uniqueMLST ->
            tuple(meta, mlst_file) }
    input = unchanged_input.mix(renamed_input)

    // Collect samples without genomic_address_name
    profiles = input.branch {
        query: !it[0].genomic_address_name
    }
    // Prepare reference and query TSV files for LOCIDEX_MERGE
    reference_values = input.collect{ meta, mlst -> mlst}
    query_values = profiles.query.collect{ meta, mlst -> mlst }

    // Query Map: Use to return meta.irida_id to output for mapping to IRIDA-Next JSON
    query_map = profiles.query.map{ meta, mlst->
        tuple(meta.id, meta.irida_id)
    }.collect()

    // LOCIDEX BLOCK
    // Two Steps: 1) Merge and 2) Concatenate

    // LOCIDEX value channels
    ref_tag   = Channel.value("ref")                                             // Seperate the reference samples
    query_tag = Channel.value("query")                                           // Seperate the query samples

    // Create channels to be used to create a MLST override file (below)
    SAMPLE_HEADER = "sample"
    MLST_HEADER   = "mlst_alleles"
    metadata_headers = Channel.of(
        tuple(
            SAMPLE_HEADER, MLST_HEADER)
        )

    metadata_rows = input.map{
        def meta = it[0]
        def mlst = it[1]
        tuple(meta.id,mlst)
    }.toList()

    merge_tsv = WRITE_METADATA (metadata_headers, metadata_rows).results.first() // MLST override file value channel

    // LOCIDEX Step 1:
    // Merge MLST files into TSV

    // 1A) Divide up inputs into groups for LOCIDEX
    def refbatchCounter = 1
    grouped_ref_files = reference_values.flatten() //
        .buffer( size: params.batch_size, remainder: true )
        .map { batch ->
        def index = refbatchCounter++
        return tuple(index, batch)
    }
    def quebatchCounter = 1
    grouped_query_files = query_values.flatten() //
        .buffer( size: params.batch_size, remainder: true )
        .map { batch ->
        def index = quebatchCounter++
        return tuple(index, batch)
    }

    // If LOCIDEX merge when run with reduce loci, the --pd_columns parameter must be set to be used with locidex merge --loci
    if (!(params.skip_prefix_background) || !(params.skip_reduce_loci)) {
            if ((!params.skip_reduce_loci) && !params.pd_columns) {
                exit 1, "error the --pd_columns parameter must be set if the --skip_reduce_loci parameter is not set."
            }
            if (params.pd_columns) {
                columns_path = file(params.pd_columns)
                // 1B) Run LOCIDEX on grouped query and reference samples with loci reduction
                references = LOCIDEX_MERGE_REF(grouped_ref_files, ref_tag, merge_tsv, columns_path)
                queries = LOCIDEX_MERGE_QUERY(grouped_query_files, query_tag, merge_tsv, columns_path)
            }
    } else {
    // 1B) Run LOCIDEX on grouped query and reference samples without loci reduction
        references = LOCIDEX_MERGE_REF(grouped_ref_files, ref_tag, merge_tsv, [])
        queries = LOCIDEX_MERGE_QUERY(grouped_query_files, query_tag, merge_tsv, [])
    }
    ch_versions = ch_versions.mix(references.versions)
    ch_versions = ch_versions.mix(queries.versions)

    // LOCIDEX Step 2:
    // Combine outputs

    // LOCIDEX Concatenate References
    combined_references = LOCIDEX_CONCAT_REF(references.combined_profiles.collect(),
        references.combined_error_report.collect(),
        ref_tag,
        references.combined_profiles.collect().flatten().count())

    // LOCIDEX Concatenate Queries
    combined_queries = LOCIDEX_CONCAT_QUERY(queries.combined_profiles.collect(),
        queries.combined_error_report.collect(),
        query_tag,
        queries.combined_profiles.collect().flatten().count())

    // Preparing and Appending additional profiles and clusters

    // APPEND_PROFILES; update expected profiles
    // APPEND_CLUSTERS; update expected clusters

    // Note: Additional reference samples to the pipeline: both --db_profiles and --db_clusters must be provided together.
    // All sample_id's in --db_profiles must match the id's in --db_clusters

    // Step 1: Generate the expected_clusters.txt file from the addresses of the provided reference samples

    clusters = input.filter { meta, file ->
        meta.genomic_address_name != null
    }.collect { meta, file ->
        meta
    }.ifEmpty([])

    initial_clusters = CLUSTER_FILE(clusters)

    // Step 2: Append the additional profiles and clusters if provided

    if(params.db_profiles && params.db_clusters) {

        // Step 2A: Prepare the additional profiles and clusters files
        // Note: If the files do not exist, the pipeline will exit with an error message

        additional_profiles = prepareFilePath(params.db_profiles, "Appending additional samples from ${params.db_profiles} to reference profiles")
        if(additional_profiles == null) {
            exit 1, "${params.db_profiles}: Does not exist but was passed to the pipeline. Exiting now."
        }
        additional_clusters = prepareFilePath(params.db_clusters, "Appending additional cluster addresses from ${params.db_clusters}")
        if(additional_clusters == null) {
            exit 1, "${params.db_clusters}: Does not exist but was passed to the pipeline. Exiting now."
        }
        // Step 2B: Preprocess and/or merge additional profiles and clusters
        // Note:
        //      - If the --skip_prefix_background parameter is set, the additional profiles will not be prefixed with '@' in
        //      in their respective columns ( profiles: sample_id clusters: id).
        //      - If the --skip_reduce_loci parameter is set, the additional profiles will not be reduced to the minimum number of loci.

        if (!(params.skip_prefix_background) || !(params.skip_reduce_loci)) {
            if ((!params.skip_reduce_loci) && !params.pd_columns) {
                exit 1, "error the --pd_columns parameter must be set if the --skip_reduce_loci parameter is not set."
            }
            if (params.pd_columns) {
                columns_path = file(params.pd_columns)
                additional_references = PREPROCESS_REFERENCES(additional_profiles, additional_clusters, columns_path)
            } else {
                additional_references = PREPROCESS_REFERENCES(additional_profiles, additional_clusters, [])
            }
            ch_versions = ch_versions.mix( additional_references.versions)

            merged_references = APPEND_PROFILES(combined_references.combined_profiles, additional_references.processed_profiles)
            expected_clusters = APPEND_CLUSTERS(initial_clusters, additional_references.processed_clusters)
        } else {
            merged_references = APPEND_PROFILES(combined_references.combined_profiles, additional_profiles)
            expected_clusters = APPEND_CLUSTERS(initial_clusters, additional_clusters)
        }
        ch_versions = ch_versions.mix( expected_clusters.versions)
        ch_versions = ch_versions.mix( merged_references.versions)
        merged_references = merged_references.combined_profiles
        expected_clusters = expected_clusters.combined_clusters
    } else {
        merged_references = combined_references.combined_profiles
        expected_clusters = initial_clusters
    }

    merged_queries = combined_queries.combined_profiles

    // PROFILE DISTS processes

    mapping_file = prepareFilePath(params.pd_mapping_file, "Selecting ${params.pd_mapping_file} for --pd_mapping_file")
    if(mapping_file == null){
        exit 1, "${params.pd_mapping_file}: Does not exist but was passed to the pipeline. Exiting now."
    }

    columns_file = prepareFilePath(params.pd_columns,  "Selecting ${params.pd_columns} for --pd_mapping_file")
    if(columns_file == null){
        exit 1, "${params.pd_columns}: Does not exist but was passed to the pipeline. Exiting now."
    }

    distances = PROFILE_DISTS(merged_queries,
                            merged_references,
                            mapping_file,
                            columns_file)
    ch_versions = ch_versions.mix(distances.versions)

    // GAS CALL processes

    if(params.gm_thresholds == null || params.gm_thresholds == ""){
        exit 1, "--gm_thresholds ${params.gm_thresholds}: Cannot pass null or empty string"
    }

    gm_thresholds_list = params.gm_thresholds.toString().split(',')
    if (params.pd_distm == 'hamming') {
        if (gm_thresholds_list.any { it != null && it.contains('.') }) {
            exit 1, ("'--pd_distm ${params.pd_distm}' is set, but '--gm_thresholds ${params.gm_thresholds}' contains fractions."
                    + " Please either set '--pd_distm scaled' or remove fractions from distance thresholds.")
        }
    } else if (params.pd_distm == 'scaled') {
        if (gm_thresholds_list.any { it != null && (it as Float < 0.0 || it as Float > 100.0) }) {
            exit 1, ("'--pd_distm ${params.pd_distm}' is set, but '--gm_thresholds ${params.gm_thresholds}' contains thresholds outside of range [0,100]."
                    + " Please either set '--pd_distm hamming' or adjust the threshold values.")
        }
    } else {
        exit 1, "'--pd_distm ${params.pd_distm}' is an invalid value. Please set to either 'hamming' or 'scaled'."
    }

    called_data = GAS_CALL(expected_clusters, distances.results)
    ch_versions = ch_versions.mix(called_data.versions)

    // Filter the new queried samples and addresses into a CSV/JSON file for the IRIDANext plug in and
    // add a column with IRIDA ID to allow for IRIDANext plugin to include metadata
    query_irida_ids = profiles.query.collectFile {  it[0].irida_id + '\t' + it[0].id + '\n'}

    new_addresses = FILTER_QUERY(query_irida_ids, called_data.distances, "tsv", "tsv")
    ch_versions = ch_versions.mix(new_addresses.versions)
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )



}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
