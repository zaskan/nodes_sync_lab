#!/bin/bash

COMMIT=$(curl -s -k -X POST https://admin:password@192.168.122.63/api/v2/job_templates/10/launch/ | jq '.job')
until [ $(curl -s -k -X GET https://admin:password@192.168.122.63/api/v2/jobs/$COMMIT/ | jq '.status') == '"successful"' ]
  do
    echo -ne "Commiting new role version...              \r"
    sleep 5
  done

TIMESTAMP=$( curl -s -k -X GET https://admin:password@192.168.122.63/api/v2/jobs/$COMMIT/ | jq '.artifacts .timestamp' | sed 's/"//g' )

UPDATE=$(curl -s -k -X POST https://admin:password@192.168.122.63/api/v2/projects/8/update/ | jq '.id')
until [ $(curl -s -k -X GET https://admin:password@192.168.122.63/api/v2/project_updates/$UPDATE/ | jq '.status') == '"successful"' ]
  do
    echo -ne "Syncing Project...                        \r"
    sleep 5
  done

NODE=$(curl -s -k -X GET https://admin:password@192.168.122.63/api/v2/project_updates/$UPDATE/ | jq '.execution_node' | sed 's/"//g')

CLEAN=$(curl -s -k -X POST https://admin:password@192.168.122.63/api/v2/system_job_templates/1/launch/ -H "Content-Type: application/json" --data '{"extra_vars": {"days": 0}}' | jq '.system_job')
until [ $(curl -s -k -X GET https://admin:password@192.168.122.63/api/v2/system_jobs/$CLEAN/ | jq '.status') == '"successful"' ]
  do
    echo -ne "Cleaning...                                \r"
    sleep 5
  done

SWITCH=$(curl -s -k -X POST https://admin:password@192.168.122.63/api/v2/job_templates/11/launch/ -H "Content-Type: application/json" --data "{\"extra_vars\": {\"controller_node\": \"$NODE\"}}" | jq '.job')
until [ $(curl -s -k -X GET https://admin:password@192.168.122.63/api/v2/jobs/$SWITCH/ | jq '.status') == '"successful"' ]
  do
    echo -ne "Switching Cluster Nodes...                    \r"
    sleep 5
  done

EXECUTE=$(curl -s -k -X POST https://admin:password@192.168.122.63/api/v2/job_templates/9/launch/ | jq '.job')
until [ $(curl -s -k -X GET https://admin:password@192.168.122.63/api/v2/jobs/$EXECUTE/ | jq '.status') == '"successful"' ]
  do
    echo -ne "Executing Job Template...                      \r"
    sleep 5
  done

EXEC_TIMESTAMP=$( curl -s -k -X GET https://admin:password@192.168.122.63/api/v2/jobs/$EXECUTE/ | jq '.artifacts .execution_timestamp' | sed 's/"//g' )

CHECK=$(curl -s -k -X POST https://admin:password@192.168.122.63/api/v2/job_templates/12/launch/ -H "Content-Type: application/json" --data "{\"extra_vars\": {\"execution_timestamp\": \"$EXEC_TIMESTAMP\", \"timestamp\": \"$TIMESTAMP\"}}" | jq '.job')
until [ $(curl -s -k -X GET https://admin:password@192.168.122.63/api/v2/jobs/$CHECK/ | jq '.status') == '"successful"' ]
  do
    echo -ne "Checking Results                                \r"
    sleep 5
  done

exec /home/rafsanch/Documents/repos/script.sh
