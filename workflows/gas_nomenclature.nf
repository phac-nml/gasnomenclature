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

    // Create a new channel of metadata from a sample sheet
    // NB: `input` corresponds to `params.input` and associated sample sheet schema
    input = Channel.fromSamplesheet("input")

    // Ensure meta.id and mlst_file keys match; generate error report for samples where id ≠ key
    id_key = INPUT_ASSURE(input)
    ch_versions = ch_versions.mix(id_key.versions)

    // Prepare reference and query TSV files for LOCIDEX_MERGE
    profiles = id_key.match.branch {
        query: !it[0].address
    }
    reference_values = input.collect{ meta, profile -> profile}
    query_values = profiles.query.collect{ meta, profile -> profile }

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

    mapping_format = Channel.value(params.pd_outfmt)

    distances = PROFILE_DISTS(merged_queries.combined_profiles,
                            merged_references.combined_profiles,
                            mapping_format,
                            mapping_file,
                            columns_file)
    ch_versions = ch_versions.mix(distances.versions)

    // GAS CALL
    clusters = Channel.fromPath(params.ref_clusters, checkIfExists: true)

    called_data = GAS_CALL(clusters, distances.results)
    ch_versions = ch_versions.mix(called_data.versions)

    // Filter the new queried samples and addresses into a CSV/JSON file for the IRIDANext plug in
    new_addresses = FILTER_QUERY(profiles.query, called_data.distances, "tsv", "csv")
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
