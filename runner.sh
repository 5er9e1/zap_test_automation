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
  $(which selenium-side-runner) --timeout 30000 --server "${CHROME_API_URL}" --proxy-type=manual --proxy-options="http=${PROXY_SERVER};https=${PROXY_SERVER}" -c "browserName=chrome goog:chromeOptions.args=[--disable-application-cache, --aggressive-cache-discard, --disable-notifications, --disable-remote-fonts, --disable-reading-from-canvas, --disable-remote-playback-api, --disable-shared-workers, --disable-voice-input, --enable-aggressive-domstorage-flushing, --headless, --disable-gpu, --proxy-server=https=${PROXY_SERVER};http=${PROXY_SERVER}] acceptInsecureCerts=true" /tmp/active.side || ERRORS="${ERRORS} ${side_script}"
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
  echo "ERROR: No report with providen filename: ${REPORT_FILE}" >&2
  exit 1
else
  echo "SUCCESS: report completed: ${REPORT_FILE}"
fi

if [ "${ERRORS}x" != "x" ]; then
  echo 'Ended with errors on' >&2
  for ERR in ${ERRORS}; do
    echo "  - ${ERR}" >&2
  done
  exit 1
fi
