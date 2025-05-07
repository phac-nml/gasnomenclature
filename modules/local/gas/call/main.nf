

process GAS_CALL{
    label "process_high"
    tag "Assigning Nomenclature"

    // Update singularlity to Galaxy depot if it becomes available.
    // Likely: // https://depot.galaxyproject.org/singularity/genomic_address_service:0.2.0--pyhdfd78af_0
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'biocontainers/genomic_address_service:0.2.0--pyhdfd78af_0' :
        'biocontainers/genomic_address_service:0.2.0--pyhdfd78af_0' }"

    input:
    path(reference_clusters)
    path(distances)

    output:
    path("${prefix}/results.{text,parquet}"), emit: distances, optional: true
    path("${prefix}/thresholds.json"), emit: thresholds
    path("${prefix}/run.json"), emit: run
    path  "versions.yml", emit: versions

    script:
    prefix = "Called"
    """
    gas call --dists $distances \\
                --rclusters $reference_clusters \\
                --outdir ${prefix} \\
                --method ${params.gm_method} \\
                --threshold ${params.gm_thresholds} \\
                --delimiter ${params.gm_delimiter}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genomic_address_service: \$( gas call -V | sed -e "s/gas//g" )
    END_VERSIONS
    """

}
