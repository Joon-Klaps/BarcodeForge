process ADD_REF_MUTS {
    tag "add_ref_muts"
    label "process_low"

    conda "${moduleDir}/environment.yml"

    input:
    path reference_genome
    path sample_paths_file
    path lineage_definition_file
    path alignment

    output:
    path '*.rerooted', emit: modified_lineage_paths
    path 'addtional_mutations.tsv'
    path 'versions.yml', emit: versions

    script:
    """
    ref_muts.py \\
        --sample_muts ${sample_paths_file} \\
        --lineage_paths ${lineage_definition_file} \\
        --reference ${reference_genome} \\
        --fasta ${alignment} \\
        --output addtional_mutations.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1)
    END_VERSIONS
    """

    stub:
    """
    touch modified_lineage_paths.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1)
    END_VERSIONS
    """
}
