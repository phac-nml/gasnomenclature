/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet  } from 'plugin/nf-validation'

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

include { INPUT_ASSURE                          } from "../modules/local/input_assure/main"
include { LOCIDEX_MERGE as LOCIDEX_MERGE_REF    } from "../modules/local/locidex/merge/main"
include { LOCIDEX_MERGE as LOCIDEX_MERGE_QUERY  } from "../modules/local/locidex/merge/main"
include { PROFILE_DISTS                         } from "../modules/local/profile_dists/main"
include { CLUSTER_FILE                          } from "../modules/local/cluster_file/main"
include { GAS_CALL                              } from "../modules/local/gas/call/main"
include { FILTER_QUERY                          } from "../modules/local/filter_query/main"

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

            tuple(meta, mlst_file)}



    // Ensure meta.id and mlst_file keys match; generate error report for samples where id ≠ key
    input_assure = INPUT_ASSURE(input)
    ch_versions = ch_versions.mix(input_assure.versions)

    // Collect samples without address
    profiles = input_assure.result.branch {
        query: !it[0].address
    }

    // Prepare reference and query TSV files for LOCIDEX_MERGE
    reference_values = input_assure.result.collect{ meta, mlst -> mlst}
    query_values = profiles.query.collect{ meta, mlst -> mlst }

    // LOCIDEX modules
    ref_tag = Channel.value("ref")
    query_tag = Channel.value("value")

    merged_references = LOCIDEX_MERGE_REF(reference_values, ref_tag)
    ch_versions = ch_versions.mix(merged_references.versions)

    merged_queries = LOCIDEX_MERGE_QUERY(query_values, query_tag)
    ch_versions = ch_versions.mix(merged_queries.versions)

    // PROFILE DISTS processes

    mapping_file = prepareFilePath(params.pd_mapping_file, "Selecting ${params.pd_mapping_file} for --pd_mapping_file")
    if(mapping_file == null){
        exit 1, "${params.pd_mapping_file}: Does not exist but was passed to the pipeline. Exiting now."
    }

    columns_file = prepareFilePath(params.pd_columns,  "Selecting ${params.pd_columns} for --pd_mapping_file")
    if(columns_file == null){
        exit 1, "${params.pd_columns}: Does not exist but was passed to the pipeline. Exiting now."
    }

    distances = PROFILE_DISTS(merged_queries.combined_profiles,
                            merged_references.combined_profiles,
                            mapping_file,
                            columns_file)
    ch_versions = ch_versions.mix(distances.versions)

    // Generate the expected_clusters.txt file from the addresses of the provided reference samples
    clusters = input.filter { meta, file ->
        meta.address != null
    }.collect { meta, file ->
        meta }

    expected_clusters = CLUSTER_FILE(clusters)

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

    called_data = GAS_CALL(expected_clusters.text, distances.results)
    ch_versions = ch_versions.mix(called_data.versions)

    // Filter the new queried samples and addresses into a CSV/JSON file for the IRIDANext plug in
    query_ids = profiles.query.collectFile { it[0].id + '\n' }

    new_addresses = FILTER_QUERY(query_ids, called_data.distances, "tsv", "csv")
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
