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
    # Function to get the first genomic address service line from the files, handling gzipped files
    get_address() {
        if [[ "\${1##*.}" == "gz" ]]; then
            # This was seemingly NOT causing 141 pipe bash errors (unlike append_profiles), but this fix was added in anticpation of the error coming up:
            zcat "\$1" | awk 'NR>1 {print \$2}'
        else
            awk 'NR>1 {print \$2}' "\$1"
        fi
    }

    # Check if two files have consistent delimeter splits in the genomic address service column
    get_address "${initial_clusters}" > initial-cluster-address.txt
    get_address "${additional_clusters}" > additional-cluster-address.txt
    init_splits=\$(head -n 1 initial-cluster-address.txt | awk -F '${params.gm_delimiter}' '{print NF}')
    add_splits=\$( head -n 1 additional-cluster-address.txt | awk -F '${params.gm_delimiter}' '{print NF}')

    if [ "\$init_splits" != "\$add_splits" ] && [ "\$init_splits" != "" ]; then
        echo "Error: Genomic address service levels do not match between initial_clusters and --db_clusters."
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
    csvtk mutate2 -t -n id -e '(\$source == "db" && \$frequency > 1) ? "db_" + \$id : \$id' | \
    csvtk cut -t -f id,address > reference_clusters.tsv
    """
}
