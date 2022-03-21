#!/bin/sh

# avoid to use spaces and special symbols in side files
ERRORS=''
for side_script in $(/bin/ls *.side); do
  cp -p "${side_script}" /tmp/active.side
  for v in ${PARAMETERS}; do
    key="$(echo "$v" | sed 's/=/ /1' | awk '{print$1}')"
    val="$(echo "$v" | sed 's/=/ /1' | awk '{print$2}')"
    sed -i "s/\${${key}}/${val}/g" /tmp/active.side
  done
  $(which selenium-side-runner) --timeout 30000 --server "${CHROME_API_URL}" --proxy-type=manual --proxy-options="http=${PROXY_SERVER};https=${PROXY_SERVER}" -c "browserName=chrome acceptInsecureCerts=true" /tmp/active.side || ERRORS="${ERRORS} ${side_script}"
  rm -f /tmp/active.side
done

if [ -z "${TEMPLATE}" ]; then
  TEMPLATE='traditional-html'
fi

urlencode=$(which urlencode)
A=$(${urlencode} "${TITLE}")
B=$(${urlencode} "${TEMPLATE}")
C=$(${urlencode} "${DESCRIPTION}")
D=$(${urlencode} "${SITES}")
E=$(${urlencode} "${REPORT_PATTERN}")
F=$(${urlencode} "${REPORT_DIR}")

URL="${ZAP_API_URL}/JSON/reports/action/generate/?title=${A}&template=${B}&theme=&description=${C}&contexts=&sites=${D}&sections=&includedConfidences=&includedRisks=&reportFileName=&reportFileNamePattern=${E}&reportDir=${F}&display=true"
REPORT_FILE_PATH=$(/usr/bin/wget -O - "${URL}" 2>/dev/null | /usr/bin/awk -F':' '{print$2}' | /bin/sed 's/[",}]//g')
REPORT_FILE=$(/usr/bin/basename "${REPORT_FILE_PATH}")

# wait while report generated
sleep 5

if [ -z "${REPORT_FILE}" ]; then
  echo "Error: empty report filename"
  exit 1
fi

mkdir -p ~/.ssh/
chmod 700 ~/.ssh/
echo -e "$(echo \"${DEPLOY_KEY_BASE64}\" | base64 -d)" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

LOCAL_REPO='/tmp/repo'
BRANCH='security_reports'
NEW_BRANCH=0

git config --global user.email "report@creator.local"
git config --global user.name "Report Creator"

git clone ${REPORT_GIT_REPO} --branch ${BRANCH} "${LOCAL_REPO}" 2>/dev/null

if [ ! -d "${LOCAL_REPO}" ]; then
  NEW_BRANCH=1
  mkdir -p "${LOCAL_REPO}"
  cd "${LOCAL_REPO}"
  git config --global init.defaultBranch ${BRANCH}
  git init
  git remote add origin ${REPORT_GIT_REPO}
else
  cd "${LOCAL_REPO}"
fi

if [ "${ERRORS}x" == "x" ]; then
  cp -p "/report/${REPORT_FILE}" .
  git add "${REPORT_FILE}"
else
  cp -p "/report/${REPORT_FILE}" "ended_with_errors_${REPORT_FILE}"
  git add "ended_with_errors_${REPORT_FILE}"
fi


git commit -m "[$(date +'%Y%m%d%H%M')] add security report: ${TITLE}"
if [ ${NEW_BRANCH} == "1" ]; then
  git push --set-upstream origin ${BRANCH}
else
  git push -u origin
fi

echo -e "" > ~/.ssh/id_rsa

if [ "${ERRORS}x" != "x" ]; then
  echo 'Ended with errors on'
  for ERR in ${ERRORS}; do
    echo "  - ${ERR}"
  done
  exit 1
fi
