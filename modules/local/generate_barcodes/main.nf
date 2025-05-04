process GENERATE_BARCODES {
    tag 'generate_barcodes'
    label 'process_low'

    conda "${moduleDir}/environment.yml"

    input:
    path lineage_definition_file
    val barcode_prefix

    output:
    path '*'
    path 'versions.yml', emit: versions

    script:
    """
    generate_barcodes.py \\
        --input ${lineage_definition_file} \\
        --prefix "${barcode_prefix}" \\
        --output ${barcode_prefix}-barcode.csv

    plot_barcode.py \\
        --input ${barcode_prefix}-barcode.csv \\
        --output ${barcode_prefix}-barcode.html
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1)
    END_VERSIONS
    """

    stub:
    """
    touch barcode.csv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1)
    END_VERSIONS
    """
}
