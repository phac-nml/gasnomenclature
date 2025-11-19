process PROFILE_DISTS{
    label "process_high"
    tag "Gathering Distances Between Reference and Query Profiles"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/profile_dists%3A1.0.10--pyhdfd78af_0' :
        'biocontainers/profile_dists:1.0.10--pyhdfd78af_0' }"

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
    def args = task.ext.args ?: ''

    if(mapping_file){
        args = "--mapping_file $mapping_file " + args
    }
    if(columns){
        args = "--columns $columns " + args
    }
    if(params.pd_max_cpus < task.cpus){
        args = "--cpus $params.pd_max_cpus " + args
    }else{
        args = "--cpus ${task.cpus} " + args
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
                -o ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        profile_dists: \$( profile_dists -V | sed -e "s/profile_dists//g" )
    END_VERSIONS
    """

}
