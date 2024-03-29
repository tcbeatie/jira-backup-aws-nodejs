#!/bin/bash

###--- CONFIGURATION SECTION STARTS HERE ---###
# MAKE SURE ALL THE VALUES IN THIS SECTION ARE CORRECT BEFORE RUNNING THE SCRIPT
HOSTNAME=$1
EMAIL=$2
API_TOKEN=$3
DOWNLOAD_FOLDER="/tmp"
touch ${DOWNLOAD_FOLDER}/$4

### Checks for progress max 3000 times, waiting 20 seconds between one check and the other ###
# If your instance is big you may want to increase the below values #
PROGRESS_CHECKS=3000
SLEEP_SECONDS=20

# Set this to your Atlassian instance's timezone.
# See this for a list of possible values:
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TIMEZONE=America/Los_Angeles

###--- END OF CONFIGURATION SECTION ---####


####- START SCRIPT -#####

TODAY=$(TZ=$TIMEZONE date +%d-%m-%Y)
echo "starting the script: $TODAY" 1>&2


## The $BKPMSG variable is used to save and print the response
BKPMSG=$(curl -s -u ${EMAIL}:${API_TOKEN} -H "Accept: application/json" -H "Content-Type: application/json" --data-binary '{"cbAttachments":"true", "exportToCloud":"true"}' -X POST https://${HOSTNAME}/rest/backup/1/export/runbackup )

## Uncomment below line to print the response message also in case of no errors ##
echo "Response: $BKPMSG" 1>&2

# If the backup did not start print the error message returned and exits the script
if [ "$(echo "$BKPMSG" | grep -ic error)" -ne 0 ]; then
  echo "BACKUP FAILED!! Message returned: $BKPMSG" 1>&2
  exit 1
fi

# If the backup started correctly it extracts the taskId value from the response
# As an alternative you can call the endpoint /rest/backup/1/export/lastTaskId to get the last task-id
TASK_ID=$(echo "$BKPMSG" | sed -n 's/.*"taskId"[ ]*:[ ]*"\([^"]*\).*/\1/p')


# Checks if the backup process completed for the number of times specified in PROGRESS_CHECKS variable
for (( c=1; c<=${PROGRESS_CHECKS}; c++ ))
  do
    PROGRESS_JSON=$(curl -s -u ${EMAIL}:${API_TOKEN} -X GET https://${HOSTNAME}/rest/backup/1/export/getProgress?taskId=${TASK_ID})
    FILE_NAME=$(echo "$PROGRESS_JSON" | sed -n 's/.*"result"[ ]*:[ ]*"\([^"]*\).*/\1/p')

# Print progress message
    echo "$PROGRESS_JSON" 1>&2

    if [[ $PROGRESS_JSON == *"error"* ]]; then
      break
    fi

    if [ ! -z "$FILE_NAME" ]; then
      break
    fi

# Waits for the amount of seconds specified in SLEEP_SECONDS variable between a check and the other
    sleep ${SLEEP_SECONDS}
  done

# If the backup is not ready after the configured amount of PROGRESS_CHECKS, it ends the script.
if [ -z "$FILE_NAME" ]; then
  exit 1
else

## PRINT THE FILE TO DOWNLOAD ##
  echo "File to download: https://${HOSTNAME}/plugins/servlet/${FILE_NAME}" 1>&2

  BACKUP_FILE=$4
  curl -s -L -u ${EMAIL}:${API_TOKEN} -X GET "https://${HOSTNAME}/plugins/servlet/${FILE_NAME}" -o ${DOWNLOAD_FOLDER}/${BACKUP_FILE}
  exit 0
fi
