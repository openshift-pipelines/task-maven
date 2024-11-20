#!/usr/bin/env bats

source ./test/helper/helper.sh

# E2E tests parameters for the test pipeline

# Testing the jib-maven task,
@test "[e2e] jib-maven task" {
    
    run tkn pipeline start task-jib-maven \
        --param="URL=${E2E_MAVEN_PARAMS_URL}" \
        --param="REVISION=${E2E_MAVEN_PARAMS_REVISION}" \
        --param="VERBOSE=true" \
        --param="IMAGE=${E2E_JIB_MAVEN_IMAGE}" \
        --workspace="name=source,claimName=task-maven,subPath=source" \
        --workspace="name=dockerconfig,secret=docker-config" \
        --filename=test/e2e/resources/pipeline-maven-jib.yaml \
        --showlog
    assert_success

    # waiting a few seconds before asserting results
	sleep 30

    # asserting the taskrun status, making sure all steps have been successful
    assert_tekton_resource "pipelinerun" --partial '(Failed: 0, Cancelled 0), Skipped: 0'
}

