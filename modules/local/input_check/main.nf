process INPUT_CHECK{
    tag "Check Sample Inputs"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(mlst)

    output:
    path("*_error_report.csv"), optional: true, emit: sample_check

    script:
    """
    input_check.py \\
        --input $mlst \\
        --sample_id ${meta.id} \\
        --output ${meta.id}_error_report.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
