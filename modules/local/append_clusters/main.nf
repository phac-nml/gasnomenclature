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
    # Function to get the header of the files, handling gzipped files
    get_header() {
        if [ "\${1##*.}" = "gz" ]; then
            zcat "\$1" | head -n 1
        else
            head -n 1 "\$1"
        fi
    }

    # Compare headers and exit if they do not match
    init_headers=\$(get_header "${initial_clusters}")
    add_headers=\$(get_header "${additional_clusters}")

    if [ "\$init_headers" != "\$add_headers" ]; then
        echo "Error: Column headers do not match between initial_clusters and --db_clusters."
        exit 1
    fi

    csvtk concat -t ${initial_clusters} ${additional_clusters} | csvtk sort -t -k id | csvtk uniq -t -f id > reference_clusters.tsv
    """
}
