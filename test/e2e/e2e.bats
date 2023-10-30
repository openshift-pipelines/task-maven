#!/usr/bin/env bats

source ./test/helper/helper.sh

# E2E tests parameters for the test pipeline

# Testing the mvn task,
@test "[e2e] mvn task" {
    [ -n "${E2E_MAVEN_PARAMS_URL}" ]
    [ -n "${E2E_MAVEN_PARAMS_REVISION}" ]

    run tkn pipeline start task-mvn \
        --param="URL=${E2E_MAVEN_PARAMS_URL}" \
        --param="REVISION=${E2E_MAVEN_PARAMS_REVISION}" \
        --param="VERBOSE=true" \
        --workspace="name=source,claimName=task-mvn,subPath=source" \
        --filename=test/e2e/resources/pipeline-mvn.yaml \
        --showlog
    assert_success

    # waiting a few seconds before asserting results
	sleep 30

    # assering the taskrun status, making sure all steps have been successful
    assert_tekton_resource "pipelinerun" --partial '(Failed: 0, Cancelled 0), Skipped: 0'
}
