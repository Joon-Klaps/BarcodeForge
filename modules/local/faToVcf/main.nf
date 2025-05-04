process FATOVCF {
    tag "fatovcf"
    label "process_low"

    conda "${moduleDir}/environment.yml"

    input:
    path alignment

    output:
    path "aligned.vcf", emit: vcf
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    fatovcf ${args} ${alignment} aligned.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fatovcf: \$(fatovcf --version 2>&1)
    END_VERSIONS
    """

    stub:
    """
    touch aligned.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fatovcf: \$(fatovcf --version 2>&1)
    END_VERSIONS
    """
}
