process MATUTILS_EXTRACT {
    tag "matutils_extract"
    label "process_low"

    conda "${moduleDir}/environment.yml"

    input:
    path annotated_tree_file

    output:
    path 'lineagePaths.txt', emit: lineage_definition_file
    path 'samplePaths.txt', emit: sample_paths_file
    path 'auspice_tree.json'
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    matUtils \\
        extract \\
        ${args} \\
        -i ${annotated_tree_file} \\
        -C lineagePaths.txt \\
        -S samplePaths.txt \\
        -j auspice_tree.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        usher: \$(usher --version 2>&1)
    END_VERSIONS
    """

    stub:
    """
    touch tree.pb

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        usher: \$(usher --version 2>&1)
    END_VERSIONS
    """
}
