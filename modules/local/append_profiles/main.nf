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
    path("profiles_ref.tsv")

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
    ref_headers=\$(get_header "${reference_profiles}")
    add_headers=\$(get_header "${additional_profiles}")

    if [ "\$ref_headers" != "\$add_headers" ]; then
        echo "Error: Column headers do not match between reference_profiles and --db_profiles."
        exit 1
    fi

    # Add a "source" column to differentiate the reference profiles and additional profiles
    csvtk mutate2 -t -n source -e " 'ref' " ${reference_profiles} > reference_profiles_source.tsv
    csvtk mutate2 -t -n source -e " 'db' " ${additional_profiles} > additional_profiles_source.tsv

    # Combine profiles from both the reference and database into a single file
    csvtk concat -t reference_profiles_source.tsv additional_profiles_source.tsv | csvtk sort -t -k sample_id > combined_profiles.tsv

    # Calculate the frequency of each sample_id across both sources
    csvtk freq -t -f sample_id combined_profiles.tsv > sample_counts.tsv

    # For any sample_id that appears in both the reference and database, add a 'db_' prefix to the sample_id from the database
    csvtk join -t -f sample_id combined_profiles.tsv sample_counts.tsv | \
    csvtk mutate2 -t -n new_sample_id -e '(\$source == "db" && \$frequency > 1) ? "db_" + \$sample_id : \$sample_id' | \
    csvtk cut -t -F -f new_sample_id,l* | \
    csvtk rename -t -f new_sample_id -n sample_id > profiles_ref.tsv
    """
}
