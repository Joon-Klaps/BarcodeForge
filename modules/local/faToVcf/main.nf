process FATOVCF {
    tag "fatovcf"
    label "process_low"

    conda "${moduleDir}/environment.yml"

    input:
    path alignment

    output:
    path "aligned.vcf", emit: vcf

    script:
    def args = task.ext.args ?: ''
    """
    faToVcf ${args} ${alignment} aligned.vcf
    """

    stub:
    """
    touch aligned.vcf
    """
}
