process MINIMAP2_ALIGN {
    tag "minimap2"
    label "process_low"

    conda "${moduleDir}/environment.yml"

    input:
    path fasta
    path reference_genome

    output:
    path "aligned.fasta", emit: alignment
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    """
    minimap2 \\
        ${args} \\
        -t ${task.cpus} \\
        -a ${reference_genome} \\
        ${fasta} | \\
        gofasta sam toMultiAlign ${args2} > aligned.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        gofasta: \$(gofasta --version 2>&1)
    END_VERSIONS
    """

    stub:
    """
    touch aligned.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        gofasta: \$(gofasta --version 2>&1)
    END_VERSIONS
    """
}
