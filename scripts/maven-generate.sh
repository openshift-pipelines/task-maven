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

if [ -n "${PARAMS_MAVEN_MIRROR_URL}" ]; then
    xml="    <mirror>\
    <id>mirror.default</id>\
    <url>${PARAMS_MAVEN_MIRROR_URL}</url>\
    <mirrorOf>central</mirrorOf>\
    </mirror>"
    sed -i "s|<!-- ### mirrors from ENV ### -->|$xml|" ${MAVEN_SETTINGS_FILE}
fi