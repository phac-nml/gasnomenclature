process PREPROCESS_REFERENCES {
    tag "Preprocess reference profiles"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/csvtk:0.22.0--h9ee0642_1' :
        'biocontainers/csvtk:0.22.0--h9ee0642_1' }"

    input:
    path(reference_profiles)
    path(reference_clusters)
    path(pd_columns)


    output:
    path("prefixed_profiles.tsv"),      emit: processed_profiles
    path("prefixed_clusters.tsv"),      emit: processed_clusters
    path "versions.yml",                emit: versions

    script:
    def commands = []


    if (!params.skip_reduce_loci) {
        // Reduce profiles to minimum number of loci
        commands.add("""
                # Function to get to perform cat or zcat for handling files that could be either gzipped or not

            cat_zcat() {
                if [ "\${1##*.}" = "gz" ]; then
                    zcat "\$1"
                else
                    cat "\$1"
                fi
            }
            columns=\$(cat_zcat $pd_columns | tr '\n' ',')
            csvtk -t cut -f sample_id,"\${columns::-1}" $reference_profiles > loci_profiles.tsv

        """)
    } else {
        commands.add("""
            ln -sf $reference_profiles loci_profiles.tsv
        """)
    }

    // Add prefix '@' to sample_id in profiles and id in clusters
    if (!params.skip_prefix_background) {
        commands.add("""
            csvtk replace -t -f sample_id -p '(.*)' -r '@\${1}' loci_profiles.tsv > prefixed_profiles.tsv
            csvtk replace -t -f id -p '(.*)' -r '@\${1}' $reference_clusters > prefixed_clusters.tsv
        """)
    } else {
        commands.add("""
            ln -sf loci_profiles.tsv prefixed_profiles.tsv
            ln -sf $reference_clusters prefixed_clusters.tsv
        """)
    }
    if (!(params.skip_prefix_background) || !(params.skip_reduce_loci)) {
        commands.add("""
            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                csvtk: \$(echo \$( csvtk version | sed -e "s/csvtk v//g" ))
            END_VERSIONS
        """)
    }
    """
    ${commands.join('\n')}
    """

}
