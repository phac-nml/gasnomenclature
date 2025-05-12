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
include { LOCIDEX_MERGE as LOCIDEX_MERGE_REF     } from "../modules/local/locidex/merge/main"
include { LOCIDEX_MERGE as LOCIDEX_MERGE_QUERY   } from "../modules/local/locidex/merge/main"
include { LOCIDEX_CONCAT as LOCIDEX_CONCAT_QUERY } from "../modules/local/locidex/concat/main"
include { LOCIDEX_CONCAT as LOCIDEX_CONCAT_REF   } from "../modules/local/locidex/concat/main"
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

    // Track processed IDs
    def processedIDs = [] as Set

    // Create a new channel of metadata from a sample sheet
    // NB: `input` corresponds to `params.input` and associated sample sheet schema
    input = Channel.fromSamplesheet("input")
    // and remove non-alphanumeric characters in sample_names (meta.id), whilst also correcting for duplicate sample_names (meta.id)
    .map { meta, mlst_file ->
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
            // Add the ID to the set of processed IDs
            processedIDs << meta.id
            tuple(meta, mlst_file)}.loadIridaSampleIds()



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

    // 1B) Run LOCIDEX on grouped query and reference samples
    references = LOCIDEX_MERGE_REF(grouped_ref_files, ref_tag, merge_tsv)
    ch_versions = ch_versions.mix(references.versions)

    queries = LOCIDEX_MERGE_QUERY(grouped_query_files, query_tag, merge_tsv)
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

    // Run APPEND_PROFILES if db_profiles parameter provided; update merged_profiles and merged_queries
    if(params.db_profiles) {
        additional_profiles = prepareFilePath(params.db_profiles, "Appending additional samples from ${params.db_profiles} to reference profiles")
        if(additional_profiles == null) {
        exit 1, "${params.db_profiles}: Does not exist but was passed to the pipeline. Exiting now."
        }

        merged_references = APPEND_PROFILES(combined_references.combined_profiles, additional_profiles)
    } else {
        merged_references = combined_references.combined_profiles
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

    // Generate the expected_clusters.txt file from the addresses of the provided reference samples
    clusters = input.filter { meta, file ->
        meta.genomic_address_name != null
    }.collect { meta, file ->
        meta
    }.ifEmpty([])

    initial_clusters = CLUSTER_FILE(clusters)

    // Run APPEND_CLUSTERS if db_clusters parameter provided
    if(params.db_clusters) {
        additional_clusters = prepareFilePath(params.db_clusters, "Appending additional cluster addresses from ${params.db_clusters}")
        if(additional_clusters == null) {
        exit 1, "${params.db_clusters}: Does not exist but was passed to the pipeline. Exiting now."
        }

        expected_clusters = APPEND_CLUSTERS(initial_clusters, additional_clusters)
    } else {
        expected_clusters = initial_clusters
    }

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
