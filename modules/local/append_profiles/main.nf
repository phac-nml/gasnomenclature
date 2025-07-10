process APPEND_PROFILES {
    tag "Append additional reference profiles"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.31.0--h9ee0642_0' :
        'biocontainers/csvtk:0.31.0--h9ee0642_0' }"

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
            # This was causing 141 pipe bash errors. A fix was added to catch this error:
            zcat "\$1" | head -n 1 || { ec="\$?"; [ "\$ec" -eq 141 ] && true || (exit "\$ec"); }
        else
            head -n 1 "\$1"
        fi
    }

    storage_space() {
        echo "\$1: Storage space"
        du -sh "\$PWD"
        du -sh /tmp
        df -h
        echo ""
    }

    storage_space "Begin"

    # Compare headers and exit if they do not match
    ref_headers=\$(get_header "${reference_profiles}")
    add_headers=\$(get_header "${additional_profiles}")

    if [ "\$ref_headers" != "\$add_headers" ]; then
        echo "Error: Column headers do not match between reference_profiles and --db_profiles."
        exit 1
    fi

    storage_space "After get headers"

    # Add a "source" column to differentiate the reference profiles and additional profiles
    csvtk mutate2 -t -n source -e " 'ref' " ${reference_profiles} > reference_profiles_source.tsv
    csvtk mutate2 -t -n source -e " 'db' " ${additional_profiles} > additional_profiles_source.tsv

    storage_space "Adding ref and db"

    # Combine profiles from both the reference and database into a single file
    csvtk concat -t reference_profiles_source.tsv additional_profiles_source.tsv > concat_profiles_tmp.tsv

    storage_space "concat profiles"

    csvtk sort -t -k sample_id concat_profiles_tmp.tsv > combined_profiles.tsv
    head combined_profiles.tsv | cut -f 1,2,3,4

    storage_space "sort profiles"

    col_num=\$(awk '{print NF}' combined_profiles.tsv | sort -nu | tail -n 1)
    n=\$((col_num -1))
    # Calculate the frequency of each sample_id across both sources
    csvtk freq -t -f sample_id combined_profiles.tsv > sample_counts.tsv

    storage_space "Calculate fequency"

    # For any sample_id that appears in both the reference and database, add a 'db_' prefix to the sample_id from the database
    csvtk join -t -f sample_id combined_profiles.tsv sample_counts.tsv |     csvtk mutate2 -t -n new_sample_id -e '(\$source == "db" && \$frequency > 1) ? "db_" + \$sample_id : \$sample_id' > tmp.txt
    csvtk cut -t -f 2-\${n} tmp.txt > tmp2.txt
    csvtk cut -t -f new_sample_id tmp.txt | csvtk rename -t -f new_sample_id -n sample_id > tmp3.txt
    paste tmp3.txt tmp2.txt > profiles_ref.tsv

    storage_space "End"

    exit 1
    """
}
