process VALIDATE {
    tag 'validate'
    label 'process_low'

    conda "${moduleDir}/environment.yml"

    input:
    path lineages
    path tree_file
    path fasta
    val tree_file_format

    output:
    path 'versions.yml', emit: versions

    script:
    """
    validate.py \\
        --lineage ${lineages} \\
        --fasta ${fasta} \\
        --tree ${tree_file} \\
        --tree_format ${tree_file_format}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1)
    END_VERSIONS
    """

    stub:
    """
    touch ${lineages}.validation_report.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1)
    END_VERSIONS
    """
}
