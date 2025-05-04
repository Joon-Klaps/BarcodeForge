/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { MINIMAP2_ALIGN } from '../modules/nf-core/minimap2/align/main'
include { FATOVCF } from '../modules/local/faToVcf/main.nf'
include { USHER } from '../modules/local/usher/main.nf'
include { MATUTILS_ANNOTATE } from '../modules/local/matutils/annotate/main.nf'
include { MATUTILS_EXTRACT } from '../modules/local/matutils/extract/main.nf'
include { ADD_REF_MUTS } from '../modules/local/add_ref_muts/main.nf'
include { GENERATE_BARCODES } from '../modules/local/generate_barcodes/main.nf'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow BARCODEFORGE {
    main:

    ch_versions = Channel.empty()

    //
    // Align the input FASTA file to the reference genome
    //
    if (params.is_aligned) {
        alignment = params.fasta
    }
    else if (params.alignment_tool == "minimap2") {
        MINIMAP2_ALIGN(params.fasta, params.reference_genome)
        alignment = MINIMAP2_ALIGN.out.alignment
    }
    else {
        println("The alignment tool ${params.alignment_tool} is not supported. Please specify 'minimap2'.")
        exit(1)
    }

    FATOVCF(alignment)

    USHER(params.tree_file, FATOVCF.out.vcf)

    MATUTILS_ANNOTATE(
        USHER.out.protobuf_tree,
        params.lineages,
    )

    MATUTILS_EXTRACT(
        MATUTILS_ANNOTATE.out.annotated_tree_file
    )

    ADD_REF_MUTS(
        params.reference_genome,
        MATUTILS_EXTRACT.out.sample_paths_file,
        MATUTILS_EXTRACT.out.lineage_definition_file,
        alignment,
    )

    GENERATE_BARCODES(ADD_REF_MUTS.out.modified_lineage_paths, params.barcode_prefix)

    ch_versions = ch_versions.mix(
        MINIMAP2_ALIGN.out.versions,
        USHER.out.versions,
        MATUTILS_ANNOTATE.out.versions,
        MATUTILS_EXTRACT.out.versions,
    )

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'barcodeforge_software_' + 'versions.yml',
            sort: true,
            newLine: true,
        )
        .set { ch_collated_versions }

    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}
