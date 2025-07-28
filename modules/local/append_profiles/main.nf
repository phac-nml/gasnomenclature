process APPEND_PROFILES {
    tag "Append additional reference profiles"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.22.0--h9ee0642_1' :
        'biocontainers/csvtk:0.22.0--h9ee0642_1' }"

    input:
    path(reference_profiles)
    path(additional_profiles)

    output:
    path("profiles_ref.tsv")

    script:

    if (additional_profiles.name.endsWith('.gz')) {
        """
        # Function to get the header of the files, handling gzipped files
        get_header() {
            if [ "\${1##*.}" = "gz" ]; then
                # This was causing 141 pipe bash errors. A fix was added to catch this error:
                zcat "\$1" | head -n 1 || { ec="\$?"; [ "\$ec" -eq 141 ] && true || (exit "\$ec"); }
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
        cat <(cat ${reference_profiles}) <(zcat ${additional_profiles} | tail -n+2) > profiles_ref.tsv
        """
    } else {
        """
        # Function to get the header of the files, handling gzipped files
        get_header() {
            if [ "\${1##*.}" = "gz" ]; then
                # This was causing 141 pipe bash errors. A fix was added to catch this error:
                zcat "\$1" | head -n 1 || { ec="\$?"; [ "\$ec" -eq 141 ] && true || (exit "\$ec"); }
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
        cat <(cat ${reference_profiles}) <(cat ${additional_profiles} | tail -n+2) > profiles_ref.tsv
        """
    }
}


