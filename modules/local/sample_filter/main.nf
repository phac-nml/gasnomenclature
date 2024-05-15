process SAMPLE_FILTER {
    tag "Filter Samples based on Metadata Conditions"
    label 'process_single'

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3'}"

    input:
    tuple val(meta), path(mlst)

    output:
    tuple val(meta), path("${meta.id}.mlst.json"), optional: true,  emit: out
    path("versions.yml"),                                           emit: versions

    script:
    """
    filter_samples.py \\
        --id ${meta.id} \\
        --address ${meta.address} \\
        --id_match ${meta.id_match} \\
        --input ${mlst} \\
        --output ${meta.id}.mlst.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
