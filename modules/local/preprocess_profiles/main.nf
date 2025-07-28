process PREPROCESS_PROFILES {
    tag "Preprocess reference profiles"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.22.0--h9ee0642_1' :
        'biocontainers/csvtk:0.22.0--h9ee0642_1' }"

    input:
    path(reference_profiles)

    output:
    path("prefixed_profiles.tsv"),      emit: processed
    path "versions.yml",                emit: versions

    script:
    """
    csvtk replace -t -f sample_id -p '(.*)' -r '@\${1}' $reference_profiles > prefixed_profiles.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
    END_VERSIONS
    """
}
