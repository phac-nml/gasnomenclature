process APPEND_PROFILES {
    tag "Append additional reference profiles"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.22.0--h9ee0642_1' :
        'biocontainers/csvtk:0.22.0--h9ee0642_1' }"

    input:
    path(reference_profiles)
    path(additional_profiles)

    output:
    path("*.tsv")

    script:
    """
    csvtk concat -t ${reference_profiles} ${additional_profiles} > profiles_ref.tsv
    """
}
