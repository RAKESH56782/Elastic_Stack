#!/bin/bash

#### Setting variables ####
CURR_DATE=$(date +"%y%m%d")
TIMESTAMP=$(date +"%y%m%d_%h%M%s")
CURR_TS=$(date)
EMAIL="XYZ@gmail.com"
SCRIPT_NAME="$0"
SCRIPT_NAME_WITHOUT_EXTENSION=$(basename -s .sh "$SCRIPT_NAME")
HOSTNAME=$(hostname)
SAMPLE_LOG_KIBANA=$(tail -n 50 /data/logs/kibana/kibana.log)
ERROR_LOG_FILE="/data/logs/service_monitoring/kibana/serviceErrorLog_${SCRIPT_NAME_WITHOUT_EXTENSION}_$CURR_DATE.log"
MONITORING_LOG_FILE="/data/logs/service_monitoring/kibana/${SCRIPT_NAME_WITHOUT_EXTENSION}_$CURR_DATE.log"
KIBANA_SERVICE_STATUS=''


echo "-------------------------${CURR_TS}---------------------------" >> "$MONITORING_LOG_FILE"
echo "[$CURR_TS][INFO] Script Start" >> "$MONITORING_LOG_FILE"
echo "[$CURR_TS][INFO] Log File - ${SCRIPT_NAME_WITHOUT_EXTENSION}_$CURR_DATE.log" >> "$MONITORING_LOG_FILE"

function get_service_status {
    KIBANA_SERVICE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5601")
    #echo "$KIBANA_SERVICE_STATUS"
    check_kibana_service
}

#### Check Kibana service status ####
function check_kibana_service {
    if [[ $KIBANA_SERVICE_STATUS == 200 || $KIBANA_SERVICE_STATUS == 302 ]]; then
        echo "[$CURR_TS][INFO] Kibana service is running" >> "$MONITORING_LOG_FILE"
        echo "[$CURR_TS][INFO] Script Finish" >> "$MONITORING_LOG_FILE"
    else
        echo "[$CURR_TS][WARNING] Kibana service is not running" >> "$MONITORING_LOG_FILE"
        echo "[$CURR_TS][WARNING] Attempting to restart Kibana service..." >> "$MONITORING_LOG_FILE"
        echo "[$CURR_TS][INFO][$SAMPLE_LOG_KIBANA]" >> "$ERROR_LOG_FILE"
        start_kibana_service
    fi
}

#### Restart kibana Service ####
function start_kibana_service {
    /data/kibana-8.1.2/bin/kibana &
    sleep 5 # Wait for 5 seconds for the service to restart
    KIBANA_SERVICE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5601")

    if [[ $KIBANA_SERVICE_STATUS == 200 || $KIBANA_SERVICE_STATUS == 302 ]]; then
        echo "[$CURR_TS][INFO] Kibana service restarted successfully" >> "$MONITORING_LOG_FILE"
        echo "[$CURR_TS][INFO] Script Finish" >> "$MONITORING_LOG_FILE"
        SERVICE_STATUS="RESTARTED"
        LOG_TYPE="WARN"
        MAIL_MESSAGE="${LOG_TYPE} The Kibana service was NOT RUNNING. The service has been started"
    else
        echo "[$CURR_TS][ERROR] Failed to restart Kibana service" >> "$MONITORING_LOG_FILE"
        echo "[$CURR_TS][INFO] Script Finish" >> "$MONITORING_LOG_FILE"
        SERVICE_STATUS="STOPPED"
        LOG_TYPE="ERROR"
        MAIL_MESSAGE="${LOG_TYPE} The Kibana service could not be starded"
    fi
    echo "${MAIL_MESSAGE}" | mail -s "'$HOSTNAME': Kibana Service ${SERVICE_STATUS}" "$EMAIL"
}

get_service_status
