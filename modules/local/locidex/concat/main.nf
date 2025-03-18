process LOCIDEX_CONCAT {
    tag 'Concat LOCIDEX files'
    label 'process_medium'

    conda "bioconda::csvtk=0.30.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.30.0--h9ee0642_0' :
        'biocontainers/csvtk:0.30.0--h9ee0642_0' }"

    input:
    path(input_profile, stageAs: "?/*") // [profiles1.tsv, profiles2.tsv, ..., profilesn.tsv]
    path(input_error,   stageAs: "?/*") // [error_report1.csv, error_report2.csv, ... , error_reportn.csv]
    val input_tag                       // makes output unique and denotes the item as the reference or query to preven name collision
    val input_count

    output:
    path("${combined_dir}/*.tsv"), emit: combined_profiles
    path("${combined_dir}/*.csv"), emit: combined_error_report, optional: true
    path "versions.yml"          , emit: versions

    script:
    combined_dir = "concat_${input_tag}"

    """
    if ((${input_count} > 1)); then
        # Concatenate the profile results
        csvtk  \\
            concat -t \\
            --num-cpus $task.cpus \\
            ${input_profile.join(' ')} \\
            -o ${combined_dir}/profile_${combined_dir}.tsv
        #
        csvtk  \\
        concat \\
            --num-cpus $task.cpus \\
            ${input_error.join(' ')} \\
            -o ${combined_dir}/MLST_error_report_${combined_dir}.csv
    else
        mkdir ${combined_dir} && mv "${input_profile}" ${combined_dir}/profile_${combined_dir}.tsv
        if ((\$(wc -l ${input_error} | cut -f1 -d" ") > 1)); then
            mv "${input_error}" ${combined_dir}/MLST_error_report_${combined_dir}.csv
        fi

    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
    END_VERSIONS
    """

    }
