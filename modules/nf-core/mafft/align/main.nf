process MAFFT_ALIGN {
    tag "mafft_align"
    label "process_medium"

    conda "${moduleDir}/environment.yml"

    input:
    path fasta
    path reference_genome

    output:
    path "aligned.fasta", emit: alignment
    path 'versions.yml', emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    mafft \\
        --auto \\ 
        --thread ${task.cpus} \\
        ${args} \\
        --addfragments \\
        ${fasta} \\
        ${reference_genome} \\
        > aligned.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mafft: \$(mafft --version 2>&1 | sed 's/^v//' | sed 's/ (.*)//')
    END_VERSIONS
    """

    stub:
    """
    touch aligned.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mafft: \$(mafft --version 2>&1 | sed 's/^v//' | sed 's/ (.*)//')
    END_VERSIONS
    """
}
