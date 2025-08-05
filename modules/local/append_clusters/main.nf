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
    path("reference_clusters.tsv"),     emit: combined_clusters
    path "versions.yml", emit: versions

    script:
    """
    # Function to get the first genomic address service line from the files, handling gzipped files
    get_address() {
        if [[ "\${1##*.}" == "gz" ]]; then
            # This was seemingly NOT causing 141 pipe bash errors (unlike append_profiles), but this fix was added in anticpation of the error coming up:
            zcat "\$1" | awk 'NR>1 {print \$2}' || { ec="\$?"; [ "\$ec" -eq 141 ] && true || (exit "\$ec"); }
        else
            awk 'NR>1 {print \$2}' "\$1"
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

    # Check if two files have consistent delimeter splits in the genomic address service column
    get_address "${initial_clusters}" > initial-cluster-address.txt
    get_address "${additional_clusters}" > additional-cluster-address.txt
    init_splits=\$(head -n 1 initial-cluster-address.txt | awk -F '${params.gm_delimiter}' '{print NF}')
    add_splits=\$( head -n 1 additional-cluster-address.txt | awk -F '${params.gm_delimiter}' '{print NF}')

    if [ "\$init_splits" != "\$add_splits" ] && [ "\$init_splits" != "" ]; then
        echo "Error: Genomic address service levels do not match between initial_clusters and --db_clusters."
        exit 1
    fi

    ref_row=\$(csvtk nrow ${initial_clusters})
    add_row=\$(csvtk nrow "${additional_clusters}")
    total_row=\$((ref_row + add_row))

    cat <(cat_zcat "${initial_clusters}") <(cat_zcat "${additional_clusters}" | tail -n+2) > reference_clusters.tsv
    final_row=\$(csvtk nrow reference_clusters.tsv)
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
