// Merge missing loci

process LOCIDEX_MERGE {
    tag 'Merge Profiles'
    label 'process_medium'
    fair true

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/locidex%3A0.3.0--pyhdfd78af_0' :
        'biocontainers/locidex:0.3.0--pyhdfd78af_0' }"


    input:
    path input_values // [file(sample1), file(sample2), file(sample3), etc...]
    val input_tag // makes output unique and denotes the item as the reference or query to preven name collision

    output:
    path("${combined_dir}/*.tsv"), emit: combined_profiles
    path "versions.yml", emit: versions

    script:
    combined_dir = "merged_${input_tag}"
    """
    locidex merge -i ${input_values.join(' ')} -o ${combined_dir}

    mv ${combined_dir}/*.tsv ${combined_dir}/merged_profiles_${input_tag}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex merge: \$(echo \$(locidex search -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """
}
