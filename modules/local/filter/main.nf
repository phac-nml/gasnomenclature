process FILTER_NEW {
    tag "Filter New Query Addresses"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.22.0--h9ee0642_1' :
        'biocontainers/csvtk:0.22.0--h9ee0642_1' }"

    input:
    val input_query
    path addresses
    val in_format
    val out_format

    output:
    path("new_addresses.csv"),  emit: csv
    path("new_addresses.json"), emit: json

    script:

    def queryID = input_query[0].id
    def outputFile = "new_addresses"

    def delimiter = in_format == "tsv" ? "\t" : (in_format == "csv" ? "," : in_format)
    def out_delimiter = out_format == "tsv" ? "\t" : (out_format == "csv" ? "," : out_format)
    def out_extension = out_format == "tsv" ? 'tsv' : 'csv'

    """
    # Filter the query samples only; keep only the 'id' and 'address' columns
    csvtk filter2 \\
        ${addresses} \\
        --filter '\$id == \"$queryID\"' \\
        --delimiter "${delimiter}" \\
        --out-delimiter "${out_delimiter}" \\
        --out-file ${outputFile}.tmp

    csvtk cut -f 1,2 ${outputFile}.tmp > ${outputFile}.${out_extension}
    rm ${outputFile}.tmp

    # Convert the CSV file to a JSON file array with 'id' as the key
    csvtk csv2json ${outputFile}.${out_extension} -k id > ${outputFile}.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
    END_VERSIONS
    """
}

