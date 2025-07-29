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
    path("profiles_ref.tsv"),           emit: combined_profiles
    path "versions.yml",                emit: versions

    script:
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

    # Function to get to perform cat or zcat for handling files that could be either gzipped or not
    cat_zcat() {
        if [ "\${1##*.}" = "gz" ]; then
            zcat "\$1"
        else
            cat "\$1"
        fi
    }

    # Compare headers and exit if they do not match
    ref_headers=\$(get_header "${reference_profiles}")
    add_headers=\$(get_header "${additional_profiles}")

    if [ "\$ref_headers" != "\$add_headers" ]; then
        echo "Error: Column headers do not match between reference_profiles and --db_profiles."
        exit 1
    fi

    ref_row=\$(csvtk nrow ${reference_profiles})
    add_row=\$(cat_zcat "${additional_profiles}" | tail -n+1 | csvtk nrow)
    total_row=\$((ref_row + add_row))

    cat <(cat_zcat "${reference_profiles}") <(cat_zcat "${additional_profiles}" | tail -n+2) > profiles_ref.tsv
    final_row=\$(csvtk nrow profiles_ref.tsv)
    if [ "\$total_row" != "\$final_row" ]; then
        echo "Error: Combining profiles did not work as expected."
        exit 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
    END_VERSIONS
    """
}
