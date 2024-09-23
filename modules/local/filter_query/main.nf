process FILTER_QUERY {
    tag "Filter New Query Addresses"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.22.0--h9ee0642_1' :
        'biocontainers/csvtk:0.22.0--h9ee0642_1' }"

    input:
    path query_ids
    path addresses
    val in_format
    val out_format

    output:
    path("new_addresses.*"),    emit: csv
    path("versions.yml"),       emit: versions

    script:
    def outputFile = "new_addresses"
    def delimiter = in_format == "tsv" ? "\t" : (in_format == "csv" ? "," : in_format)
    def out_delimiter = out_format == "tsv" ? "\t" : (out_format == "csv" ? "," : out_format)
    def out_extension = out_format == "tsv" ? 'tsv' : 'csv'

    """
    # Filter the query samples only; keep only the 'id' and 'address' columns
    csvtk grep \\
        ${addresses} \\
        -f 1 \\
        -P ${query_ids} \\
        --delimiter "${delimiter}" \\
        --out-delimiter "${out_delimiter}" | \\
    csvtk cut -f id,address > ${outputFile}.${out_extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
    END_VERSIONS
    """
}
