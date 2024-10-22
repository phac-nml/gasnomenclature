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

    # Add a "source" column to differentiate the reference profiles and additional profiles
    csvtk mutate2 -t -n source -e " 'ref' " ${initial_clusters} > reference_clusters_source.tsv
    csvtk mutate2 -t -n source -e " 'db' " ${additional_clusters} > additional_clusters_source.tsv

    # Combine profiles from both the reference and database into a single file
    csvtk concat -t reference_clusters_source.tsv additional_clusters_source.tsv | csvtk sort -t -k id > combined_profiles.tsv

    # Calculate the frequency of each sample_id across both sources
    csvtk freq -t -f id combined_profiles.tsv > sample_counts.tsv

    # For any sample_id that appears in both the reference and database, add a 'db_' prefix to the sample_id from the database
    csvtk join -t -f id combined_profiles.tsv sample_counts.tsv | \
    csvtk mutate2 -t -n new_id -e '(\$source == "db" && \$frequency > 1) ? "db_" + \$id : \$id' | \
    csvtk cut -t -F -f new_id,address,level_* | \
    csvtk rename -t -f new_id -n id > reference_clusters.tsv
     """
}
