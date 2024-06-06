process INPUT_ASSURE {
    tag "Check Sample Inputs and Generate Error Report"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(mlst)

    output:
    tuple val(meta), path("${meta.id}_match.txt"), path(mlst),      emit: match
    tuple val(meta), path("*_error_report.csv"), optional: true,    emit: error_report
    path("versions.yml"),                                           emit: versions

    script:

    """
    input_check.py \\
        --input ${mlst} \\
        --sample_id ${meta.id} \\
        --address ${meta.address} \\
        --output_error ${meta.id}_error_report.csv \\
        --output_match ${meta.id}_match.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
