process INPUT_CHECK{
    tag "Check Sample Inputs"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"

    input:
    tuple val(meta), path(mlst)

    output:
    tuple val(meta), path("${meta.id}_match.txt"), path(mlst),  emit: match
    path("versions.yml"),                                       emit: versions

    script:

    """
    input_check.py \\
        --input ${mlst} \\
        --sample_id ${meta.id} \\
        --output ${meta.id}_match.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

}
