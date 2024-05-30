process CLUSTER_FILE {
    tag "Create cluster file for GAS call"
    label 'process_single'

    input:
    val meta

    output:
    path("expected_clusters.txt"), emit: text

    exec:
    def outputLines = []

    // Determine the maximum number of levels to set the header requirements for each pipeline run
    int maxLevels = meta.collect { sample -> sample.address.split("\\$params.gm_delimiter").size() }.max() ?: 0

    // Verify each sample is consistent with $maxLevels
    meta.each { sample ->
        int level = sample.address.split("\\$params.gm_delimiter").size()
        if (level != maxLevels) {
            error ("Inconsistent levels found: expected $maxLevels levels but found $level levels in ${sample.id}")
        }
    }

    // Generate the header for the expected_clusters.txt file
    def header = ["id", "address"] + (1..maxLevels).collect { "level_$it" }
    outputLines << header.join("\t")

    // Iterate over each sample in the meta list and pull the relevant information for the text file
    meta.each { sample ->
        def id = sample.id
        def address = sample.address
        def levels = address.split("\\$params.gm_delimiter")
        def line = [id, address] + levels.collect { it.toString() } + (levels.size()..<maxLevels).collect { "" }
        outputLines << line.join("\t")
    }

    // Write the text file, iterating over each sample
    task.workDir.resolve("expected_clusters.txt").withWriter { writer ->
        outputLines.each { line ->
            writer.writeLine(line)
        }
    }
}
