#!/usr/bin/env bats

source ./test/helper/helper.sh

# E2E tests parameters for the test pipeline

# Testing the maven task,
@test "[e2e] maven task" {
    [ -n "${E2E_MAVEN_PARAMS_URL}" ]
    [ -n "${E2E_MAVEN_PARAMS_REVISION}" ]
    [ -n "${E2E_MAVEN_PARAMS_SERVER_SECRET}" ]
    [ -n "${E2E_MAVEN_PARAMS_PROXY_SECRET}" ]
    [ -n "${E2E_MAVEN_PARAMS_PROXY_CONFIGMAP}" ]
    
    run tkn pipeline start task-maven \
        --param="URL=${E2E_MAVEN_PARAMS_URL}" \
        --param="REVISION=${E2E_MAVEN_PARAMS_REVISION}" \
        --param="VERBOSE=true" \
        --workspace="name=server_secret,secret=${E2E_MAVEN_PARAMS_SERVER_SECRET}" \
        --workspace="name=proxy_secret,secret=${E2E_MAVEN_PARAMS_PROXY_SECRET}" \
        --workspace="name=proxy_configmap,secret=${E2E_MAVEN_PARAMS_PROXY_CONFIGMAP}" \
        --workspace name=maven_settings,volumeClaimTemplateFile=./test/e2e/resources/workspace-template.yaml \
        --workspace="name=source,claimName=task-maven,subPath=source" \
        --filename=test/e2e/resources/pipeline-maven.yaml \
        --showlog
    assert_success

    # waiting a few seconds before asserting results
	sleep 30

    # assering the taskrun status, making sure all steps have been successful
    assert_tekton_resource "pipelinerun" --partial '(Failed: 0, Cancelled 0), Skipped: 0'
}
