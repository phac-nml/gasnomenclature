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
    # Compare headers ad exit if they do not match
    init_headers=\$(head -n 1 "${initial_clusters}")
    add_headers=\$(head -n 1 "${additional_clusters}")

    if [ "\$init_headers" != "\$add_headers" ]; then
        echo "Error: Column headers do not match between initial_clusters and --db_clusters."
        exit 1
    fi

    csvtk concat -t ${initial_clusters} ${additional_clusters} > all_clusters.tsv
    csvtk uniq -t -f id all_clusters.tsv > reference_clusters.tsv
    """
}
