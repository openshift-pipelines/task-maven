#!/usr/bin/env bash

declare -rx MAVEN_GENERATE_DIRECTORY="${WORKSPACES_SOURCE_PATH}/maven-generate"

declare -rx MAVEN_SETTINGS_FILE="${MAVEN_GENERATE_DIRECTORY}/settings.xml"

if [[ -f ${MAVEN_SETTINGS_FILE} ]]; then
    echo "using existing '${MAVEN_SETTINGS_FILE}'"
    cat ${MAVEN_SETTINGS_FILE}
    exit 0
fi

mkdir "${MAVEN_GENERATE_DIRECTORY}"

cat > "${MAVEN_SETTINGS_FILE}" <<EOF
<settings>
    <servers>
    <!-- The servers added here are generated from environment variables. Don't change. -->
    <!-- ### SERVER's USER INFO from ENV ### -->
    </servers>
    <mirrors>
    <!-- The mirrors added here are generated from environment variables. Don't change. -->
    <!-- ### mirrors from ENV ### -->
    </mirrors>
    <proxies>
    <!-- The proxies added here are generated from environment variables. Don't change. -->
    <!-- ### HTTP proxy from ENV ### -->
    </proxies>
</settings>
EOF

cat "${MAVEN_SETTINGS_FILE}"

xml=""
if [[ "${WORKSPACES_PROXY_SECRET_BOUND}" == "true" ]]; then
    if test -f ${WORKSPACES_PROXY_SECRET_PATH}/username && test -f ${WORKSPACES_PROXY_SECRET_PATH}/password; then
    PARAMS_PROXY_USER=$(cat ${WORKSPACES_PROXY_SECRET_PATH}/username)
    PARAMS_PROXY_PASSWORD=$(cat ${WORKSPACES_PROXY_SECRET_PATH}/password)

    # Fetching proxy configuration values from ConfigMap workspace
    PARAMS_PROXY_HOST=$(cat ${WORKSPACES_PROXY_CONFIGMAP_PATH}/proxy_host)
    PARAMS_PROXY_PORT=$(cat ${WORKSPACES_PROXY_CONFIGMAP_PATH}/proxy_port)
    PARAMS_PROXY_PROTOCOL=$(cat ${WORKSPACES_PROXY_CONFIGMAP_PATH}/proxy_protocol)
    PARAMS_PROXY_NON_PROXY_HOSTS=$(cat ${WORKSPACES_PROXY_CONFIGMAP_PATH}/proxy_non_proxy_hosts)

    if [ -n "${PARAMS_PROXY_HOST}" -a -n "${PARAMS_PROXY_PORT}" ]; then
        xml="<proxy>\
        <id>genproxy</id>\
        <active>true</active>\
        <protocol>${PARAMS_PROXY_PROTOCOL}</protocol>\
        <host>${PARAMS_PROXY_HOST}</host>\
        <port>${PARAMS_PROXY_PORT}</port>"
        if [ -n "${PARAMS_PROXY_USER}" -a -n "${PARAMS_PROXY_PASSWORD}" ]; then
            xml="$xml\
            <username>${PARAMS_PROXY_USER}</username>\
            <password>${PARAMS_PROXY_PASSWORD}</password>"
        fi
        if [ -n "${PARAMS_PROXY_NON_PROXY_HOSTS}" ]; then
            xml="$xml\
            <nonProxyHosts>${PARAMS_PROXY_NON_PROXY_HOSTS}</nonProxyHosts>"
        fi
        xml="$xml\
        </proxy>"
        sed -i "s|<!-- ### HTTP proxy from ENV ### -->|$xml|" ${MAVEN_SETTINGS_FILE}
    fi
    else
        echo "no 'username' or 'password' file found at workspace proxy_secret"
        exit 1
    fi
fi

if [[ "${WORKSPACES_SERVER_SECRET_BOUND}" == "true" ]]; then
    if test -f ${WORKSPACES_SERVER_SECRET_PATH}/username && test -f${WORKSPACES_SERVER_SECRET_PATH}/password; then
	SERVER_USER=$(cat ${WORKSPACES_SERVER_SECRET_PATH}/username)
	SERVER_PASSWORD=$(cat ${WORKSPACES_SERVER_SECRET_PATH}/password)
	if [ -n "${SERVER_USER}" -a -n "${SERVER_PASSWORD}" ]; then
	    xml="<server>\
        <id>serverid</id>"
	    xml="$xml\
        <username>${SERVER_USER}</username>\
        <password>${SERVER_PASSWORD}</password>"
	    xml="$xml\
        </server>"
	    sed -i "s|<!-- ### SERVER's USER INFO from ENV ### -->|$xml|" ${MAVEN_SETTINGS_FILE}
	    echo "SERVER Creds Updated"
	fi
    else
	echo "no 'user' or 'password' file found at workspace server_secret"
        exit 1
    fi
fi

if [ -n "${PARAMS_MAVEN_MIRROR_URL}" ]; then
    xml="    <mirror>\
    <id>mirror.default</id>\
    <url>${PARAMS_MAVEN_MIRROR_URL}</url>\
    <mirrorOf>central</mirrorOf>\
    </mirror>"
    sed -i "s|<!-- ### mirrors from ENV ### -->|$xml|" ${MAVEN_SETTINGS_FILE}
fi
