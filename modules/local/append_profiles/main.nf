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

    # Merge profiles ensuring only unique samples are added
    csvtk concat -t ${reference_profiles} ${additional_profiles} > profiles.tsv
    csvtk uniq -t -f sample_id profiles.tsv > profiles_ref.tsv
    """
}
