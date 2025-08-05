process PREPROCESS_REFERENCES {
    tag "Preprocess reference profiles"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.22.0--h9ee0642_1' :
        'biocontainers/csvtk:0.22.0--h9ee0642_1' }"

    input:
    path(reference_profiles)
    path(reference_clusters)

    output:
    path("prefixed_profiles.tsv"),      emit: processed_profiles
    path("prefixed_clusters.tsv"),      emit: processed_clusters
    path "versions.yml",                emit: versions

    script:
    """
    csvtk replace -t -f sample_id -p '(.*)' -r '@\${1}' $reference_profiles > prefixed_profiles.tsv
    csvtk replace -t -f id -p '(.*)' -r '@\${1}' $reference_clusters > prefixed_clusters.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
    END_VERSIONS
    """
}
