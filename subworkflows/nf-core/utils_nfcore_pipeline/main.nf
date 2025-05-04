//
// Subworkflow with utility functions specific to the nf-core pipeline template
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW DEFINITION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow UTILS_NFCORE_PIPELINE {
    take:
    nextflow_cli_args

    main:
    valid_config = checkConfigProvided()
    checkProfileProvided(nextflow_cli_args)

    emit:
    valid_config
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
//  Warn if a -profile or Nextflow config has not been provided to run the pipeline
//
def checkConfigProvided() {
    def valid_config = true as Boolean
    if (workflow.profile == 'standard' && workflow.configFiles.size() <= 1) {
        log.warn(
            "[${workflow.manifest.name}] You are attempting to run the pipeline without any custom configuration!\n\n" + "This will be dependent on your local compute environment but can be achieved via one or more of the following:\n" + "   (1) Using an existing pipeline profile e.g. `-profile docker` or `-profile singularity`\n" + "   (2) Using an existing nf-core/configs for your Institution e.g. `-profile crick` or `-profile uppmax`\n" + "   (3) Using your own local custom config e.g. `-c /path/to/your/custom.config`\n\n" + "Please refer to the quick start section and usage docs for the pipeline.\n "
        )
        valid_config = false
    }
    return valid_config
}

//
// Exit pipeline if --profile contains spaces
//
def checkProfileProvided(nextflow_cli_args) {
    if (workflow.profile.endsWith(',')) {
        error(
            "The `-profile` option cannot end with a trailing comma, please remove it and re-run the pipeline!\n" + "HINT: A common mistake is to provide multiple values separated by spaces e.g. `-profile test, docker`.\n"
        )
    }
    if (nextflow_cli_args[0]) {
        log.warn(
            "nf-core pipelines do not accept positional arguments. The positional argument `${nextflow_cli_args[0]}` has been detected.\n" + "HINT: A common mistake is to provide multiple values separated by spaces e.g. `-profile test, docker`.\n"
        )
    }
}

//
// Generate workflow version string
//
def getWorkflowVersion() {
    def version_string = "" as String
    if (workflow.manifest.version) {
        def prefix_v = workflow.manifest.version[0] != 'v' ? 'v' : ''
        version_string += "${prefix_v}${workflow.manifest.version}"
    }

    if (workflow.commitId) {
        def git_shortsha = workflow.commitId.substring(0, 7)
        version_string += "-g${git_shortsha}"
    }

    return version_string
}

//
// Get software versions for pipeline
//
def processVersionsFromYAML(yaml_file) {
    def yaml = new org.yaml.snakeyaml.Yaml()
    def versions = yaml.load(yaml_file).collectEntries { k, v -> [k.tokenize(':')[-1], v] }
    return yaml.dumpAsMap(versions).trim()
}

//
// Get workflow version for pipeline
//
def workflowVersionToYAML() {
    return """
    Workflow:
        ${workflow.manifest.name}: ${getWorkflowVersion()}
        Nextflow: ${workflow.nextflow.version}
    """.stripIndent().trim()
}

//
// Get channel of software versions used in pipeline in YAML format
//
def softwareVersionsToYAML(ch_versions) {
    return ch_versions.unique().map { version -> processVersionsFromYAML(version) }.unique().mix(Channel.of(workflowVersionToYAML()))
}

//
// ANSII colours used for terminal logging
//
def logColours() {
    def colorcodes = [:] as Map

    // Reset / Meta
    colorcodes['reset'] = "\033[0m"
    colorcodes['bold'] = "\033[1m"
    colorcodes['dim'] = "\033[2m"
    colorcodes['underlined'] = "\033[4m"
    colorcodes['blink'] = "\033[5m"
    colorcodes['reverse'] = "\033[7m"
    colorcodes['hidden'] = "\033[8m"

    // Regular Colors
    colorcodes['black'] = "\033[0;30m"
    colorcodes['red'] = "\033[0;31m"
    colorcodes['green'] = "\033[0;32m"
    colorcodes['yellow'] = "\033[0;33m"
    colorcodes['blue'] = "\033[0;34m"
    colorcodes['purple'] = "\033[0;35m"
    colorcodes['cyan'] = "\033[0;36m"
    colorcodes['white'] = "\033[0;37m"

    // Bold
    colorcodes['bblack'] = "\033[1;30m"
    colorcodes['bred'] = "\033[1;31m"
    colorcodes['bgreen'] = "\033[1;32m"
    colorcodes['byellow'] = "\033[1;33m"
    colorcodes['bblue'] = "\033[1;34m"
    colorcodes['bpurple'] = "\033[1;35m"
    colorcodes['bcyan'] = "\033[1;36m"
    colorcodes['bwhite'] = "\033[1;37m"

    // Underline
    colorcodes['ublack'] = "\033[4;30m"
    colorcodes['ured'] = "\033[4;31m"
    colorcodes['ugreen'] = "\033[4;32m"
    colorcodes['uyellow'] = "\033[4;33m"
    colorcodes['ublue'] = "\033[4;34m"
    colorcodes['upurple'] = "\033[4;35m"
    colorcodes['ucyan'] = "\033[4;36m"
    colorcodes['uwhite'] = "\033[4;37m"

    // High Intensity
    colorcodes['iblack'] = "\033[0;90m"
    colorcodes['ired'] = "\033[0;91m"
    colorcodes['igreen'] = "\033[0;92m"
    colorcodes['iyellow'] = "\033[0;93m"
    colorcodes['iblue'] = "\033[0;94m"
    colorcodes['ipurple'] = "\033[0;95m"
    colorcodes['icyan'] = "\033[0;96m"
    colorcodes['iwhite'] = "\033[0;97m"

    // Bold High Intensity
    colorcodes['biblack'] = "\033[1;90m"
    colorcodes['bired'] = "\033[1;91m"
    colorcodes['bigreen'] = "\033[1;92m"
    colorcodes['biyellow'] = "\033[1;93m"
    colorcodes['biblue'] = "\033[1;94m"
    colorcodes['bipurple'] = "\033[1;95m"
    colorcodes['bicyan'] = "\033[1;96m"
    colorcodes['biwhite'] = "\033[1;97m"

    return colorcodes
}

//
// Print pipeline summary on completion
//
def completionSummary() {
    def colors = logColours() as Map
    if (workflow.success) {
        if (workflow.stats.ignoredCount == 0) {
            log.info("-${colors.purple}[${workflow.manifest.name}]${colors.green} Pipeline completed successfully${colors.reset}-")
        }
        else {
            log.info("-${colors.purple}[${workflow.manifest.name}]${colors.yellow} Pipeline completed successfully, but with errored process(es) ${colors.reset}-")
        }
    }
    else {
        log.info("-${colors.purple}[${workflow.manifest.name}]${colors.red} Pipeline completed with errors${colors.reset}-")
    }
}
