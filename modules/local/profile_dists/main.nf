process PROFILE_DISTS{
    label "process_high"
    tag "Gathering Distances Between Reference and Query Profiles"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/mwells14/profile_dists:1.0.2' :
        task.ext.override_configured_container_registry != false ? 'docker.io/mwells14/profile_dists:1.0.2' :
        'mwells14/profile_dists:1.0.2' }"

    input:
    path query
    path ref
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
    if(params.pd_skip){
        args = args + " --skip"
    }
    if(params.pd_count_missing){
        args = args + " --count_missing"
    }
    // --match_threshold $params.profile_dists.match_thresh \\
    prefix = "distances_pairwise"
    """
    profile_dists --query $query --ref $ref $args \\
                --outfmt pairwise \\
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
