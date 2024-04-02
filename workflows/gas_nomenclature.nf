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

include { GENERATE_SAMPLE_JSON } from '../modules/local/generatesamplejson/main'
include { SIMPLIFY_IRIDA_JSON  } from '../modules/local/simplifyiridajson/main'
include { IRIDA_NEXT_OUTPUT    } from '../modules/local/iridanextoutput/main'
include { GENERATE_SUMMARY     } from '../modules/local/generatesummary/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { LOCIDEX_MERGE } from "../modules/local/locidex/merge/main"
include { GAS_CALL } from "../modules/local/gas/call/main"
include { PROFILE_DISTS } from "../modules/local/profile_dists/main"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GAS_NOMENCLATURE {

    ch_versions = Channel.empty()

    // Create a new channel of metadata from a sample sheet
    // NB: `input` corresponds to `params.input` and associated sample sheet schema
    input = Channel.fromSamplesheet("input").map { meta, profile -> tuple(meta, file(profile))};
    profiles = input.map{
        it -> it[1]
    }.collect()
    LOCIDEX_MERGE(profiles)


    // A channel of tuples of ({meta}, [read[0], read[1]], assembly)
    //ch_tuple_read_assembly = input.join(ASSEMBLY_STUB.out.assembly)

    //GENERATE_SAMPLE_JSON (
    //    ch_tuple_read_assembly
    //)
    //ch_versions = ch_versions.mix(GENERATE_SAMPLE_JSON.out.versions)

    //GENERATE_SUMMARY (
    //    ch_tuple_read_assembly.collect{ [it] }
    //)
    //ch_versions = ch_versions.mix(GENERATE_SUMMARY.out.versions)

    //SIMPLIFY_IRIDA_JSON (
    //    GENERATE_SAMPLE_JSON.out.json
    //)
    //ch_versions = ch_versions.mix(SIMPLIFY_IRIDA_JSON.out.versions)
    //ch_simplified_jsons = SIMPLIFY_IRIDA_JSON.out.simple_json.map { meta, data -> data }.collect() // Collect JSONs

    //IRIDA_NEXT_OUTPUT (
    //    samples_data=ch_simplified_jsons
    //)
    //ch_versions = ch_versions.mix(IRIDA_NEXT_OUTPUT.out.versions)

    //CUSTOM_DUMPSOFTWAREVERSIONS (
    //    ch_versions.unique().collectFile(name: 'collated_versions.yml')
    //)
}



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
