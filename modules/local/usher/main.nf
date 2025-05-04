process USHER {
    tag "usher"
    label "process_low"

    conda "${moduleDir}/environment.yml"

    input:
    path tree
    path vcf

    output:
    path "tree.pb", emit: protobuf_tree
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    """
    sed ${args} -re "s/['\\"]//g;" ${tree} > tree.noQuotes.nwk
    usher ${args2} -t tree.noQuotes.nwk -v ${vcf} -o tree.pb -T ${task.cpus}

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
