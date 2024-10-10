process APPEND_CLUSTERS {
    tag "Append additional clusters from database"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.22.0--h9ee0642_1' :
        'biocontainers/csvtk:0.22.0--h9ee0642_1' }"

    input:
    path(initial_clusters)
    path(additional_clusters)

    output:
    path("reference_clusters.tsv")

    script:
    """
    csvtk concat -t ${initial_clusters} ${additional_clusters} > reference_clusters.tsv

    """
}
