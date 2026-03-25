#!/bin/bash

declare -rx DOCKER_CONFIG="${WORKSPACES_DOCKERCONFIG_PATH}"

# Delete the truststore created on exit
function cleanup {
    rm "${WORKSPACES_SOURCE_PATH}/truststore.jks"
}

certParams=""

if [[ -f "${WORKSPACES_SSLCERTDIR_PATH}/${PARAMS_CACERTFILE}" ]]; then
    # create the truststore with existing certs available
    keytool -importkeystore -srckeystore "$JAVA_HOME/lib/security/cacerts" -srcstoretype JKS -destkeystore "${WORKSPACES_SOURCE_PATH}/truststore.jks" -storepass "changeit" -srcstorepass "changeit" > /tmp/logs 2>&1
    if [ $? -ne 0 ]; then
        cat /tmp/logs
        exit 1
    fi
    # add your certs to the new truststore created
    keytool -import -keystore "${WORKSPACES_SOURCE_PATH}/truststore.jks" -storepass "changeit" -file "${WORKSPACES_SSLCERTDIR_PATH}/${PARAMS_CACERTFILE}" -noprompt
    # pass truststore details to the mvn command
    certParams="-Djavax.net.ssl.trustStore=${WORKSPACES_SOURCE_PATH}/truststore.jks -Djavax.net.ssl.trustStorePassword=changeit"
    # clean truststore on exit
    trap cleanup EXIT
fi

# Build and push the image
mvn -B \
    -Duser.home="$HOME" \
    -Djib.allowInsecureRegistries="${PARAMS_INSECUREREGISTRY}" \
    -Djib.to.image="${PARAMS_IMAGE}" \
    $certParams \
    compile \
    com.google.cloud.tools:jib-maven-plugin:build

cat ${WORKSPACES_SOURCE_PATH}/${PARAMS_DIRECTORY}/target/jib-image.digest | tee ${RESULTS_IMAGE_DIGEST_PATH}