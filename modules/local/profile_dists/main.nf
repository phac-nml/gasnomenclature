process PROFILE_DISTS{
    label "process_high"
    tag "Gathering Distances Between Reference and Query Profiles"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/profile_dists%3A1.0.0--pyh7cba7a3_0' :
        'quay.io/biocontainers/profile_dists:1.0.0--pyh7cba7a3_0' }"

    input:
    path query
    path ref
    val mapping_format
    path mapping_file
    path columns


    output:
    path("${prefix}/allele_map.json"), emit: allele_map
    path("${prefix}/query_profile.{text,parquet}"), emit: query_profile
    path("${prefix}/ref_profile.{text,parquet}"), emit: ref_profile
    path("${prefix}/results.{text,parquet}"), emit: results
    path("${prefix}/run.json"), emit: run
    path  "versions.yml", emit: versions


    script:
    def args = ""

    if(mapping_file){
        args = args + "--mapping_file $mapping_file"
    }
    if(columns){
        args = args + " --columns $columns"
    }
    if(params.pd_force){
        args = args + " --force"
    }
    if(params.pd_skip){
        args = args + " --skip"
    }
    if(params.pd_count_missing){
        args = args + " --count_missing"
    }
    // --match_threshold $params.profile_dists.match_thresh \\
    prefix = "distances_${mapping_format}"
    """
    profile_dists --query $query --ref $ref $args --outfmt $mapping_format \\
                --distm $params.pd_distm \\
                --file_type $params.pd_file_type \\
                --missing_thresh $params.pd_missing_threshold \\
                --sample_qual_thresh $params.pd_sample_quality_threshold \\
                --max_mem ${task.memory.toGiga()} \\
                --cpus ${task.cpus} \\
                -o ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        profile_dists: \$( profile_dists -V | sed -e "s/profile_dists//g" )
    END_VERSIONS
    """

}
