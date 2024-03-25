// Merge missing loci

process LOCIDEX_MERGE {
    tag 'Merge Profiles'
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/locidex:0.1.1--pyhdfd78af_0' :
    'quay.io/biocontainers/locidex:0.1.1--pyhdfd78af_0' }"

    input:
    val input_values // [file(sample1), file(sample2), file(sample3), etc...]

    output:
    path("${combined_dir}/*.tsv"), emit: combined_profiles
    path("${combined_dir}/*.json"), emit: report
    path "versions.yml", emit: versions

    script:
    combined_dir = "merged"
    """
    locidex merge -i ${input_values.join(' ')} -o ${combined_dir}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex merge: \$(echo \$(locidex search -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """
}
