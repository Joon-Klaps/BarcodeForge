# Description: Makefile for Nextflow pipeline development

.PHONY: clean md5sum test run-test

clean:
	rm -rf work/ results .nextflow.log* .nextflow/

md5sum:
	bash assets/test/md5.sh

run-test-nwk:
	nextflow run main.nf -profile test,mamba -params-file assets/test/input/params_nwk.json

run-test-nexus:
	nextflow run main.nf -profile test,mamba -params-file assets/test/input/params_nexus.json

test: clean
	$(MAKE) run-test-nwk
	$(MAKE) md5sum
	rm -rf results/
	$(MAKE) run-test-nexus
	$(MAKE) md5sum
