process LOCIDEX_CONCAT {
    tag 'Concat LOCIDEX files'
    label 'process_medium'

    conda "bioconda::csvtk=0.30.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.30.0--h9ee0642_0' :
        'biocontainers/csvtk:0.30.0--h9ee0642_0' }"

    input:
    path(input_values, stageAs: "?/*") // [file(sample1), file(sample2), file(sample3), etc...]
    val input_tag // makes output unique and denotes the item as the reference or query to preven name collision
    val input_count

    output:
    path("${combined_dir}/*.tsv"), emit: combined_profiles
    path "versions.yml"          , emit: versions

    script:
    combined_dir = "merged_${input_tag}"

    """
    if ((${input_count} > 1)); then
        csvtk  \\
            concat -t \\
            --num-cpus $task.cpus \\
            ${input_values.join(' ')} \\
            -o ${combined_dir}/${combined_dir}.tsv
    else
        mkdir ${combined_dir} && mv "${input_values}" ${combined_dir}/${combined_dir}.tsv

    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
    END_VERSIONS
    """

    }
