

process GAS_CALL{
    label "process_high"
    tag "Calling: ${meta.id}"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/genomic_address_service%3A0.1.1--pyh7cba7a3_1' :
        'quay.io/biocontainers/genomic_address_service:0.1.1--pyh7cba7a3_1' }"


    input:
    tuple val(meta), path(reference_clusters), path(distances)

    output:
    tuple val(meta), path("${prefix}/results.{text,parquet}"), emit: distances, optional: true
    tuple val(meta), path("${prefix}/thresholds.json"), emit: thresholds
    tuple val(meta), path("${prefix}/run.json"), emit: run
    path  "versions.yml", emit: versions

    script:
    // Need to add more args for gas call below
    prefix = meta.id
    """
    gas call --dists $distances \\
                --rclusters $reference_clusters \\
                --outdir ${prefix} \\
                --threshold ${params.gm_thresholds} \\
                --delimeter ${params.gm_delimiter}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genomic_address_service: \$( gas call -V | sed -e "s/gas//g" )
    END_VERSIONS
    """

}
