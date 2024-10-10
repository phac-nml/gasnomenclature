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
    path("new_addresses.*"),    emit: tsv
    path("versions.yml"),       emit: versions

    script:
    def outputFile = "new_addresses"
    def delimiter = in_format == "tsv" ? "\t" : (in_format == "csv" ? "," : in_format)
    def out_delimiter = out_format == "tsv" ? "\t" : (out_format == "csv" ? "," : out_format)
    def out_extension = out_format == "tsv" ? 'tsv' : 'csv'

    """
    # Filter the query samples only; keep only the 'id' and 'address' columns
    csvtk cut -t -f 2 ${query_ids} > query_list.txt # Need to use the second column to pull meta.id because there is no header
    csvtk add-header ${query_ids} -t -n irida_id,id > id.txt
    csvtk grep \\
        ${addresses} \\
        -f 1 \\
        -P query_list.txt \\
        --delimiter "${delimiter}" \\
        --out-delimiter "${out_delimiter}" | \\
    csvtk cut -t -f id,address > tmp.tsv
    csvtk join -t -f id id.txt tmp.tsv > ${outputFile}.${out_extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
    END_VERSIONS
    """
}
