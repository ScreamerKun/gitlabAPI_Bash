#!/bin/bash

echo "Content-Type: application/xml"
echo ""

# Чтение данных POST-запроса
read -r POST_DATA

# Извлечение переменных из POST_DATA
VAR1=$(echo "$POST_DATA" | grep -oP "(?<=VAR1=)[^&]+")
VAR2=$(echo "$POST_DATA" | grep -oP "(?<=VAR2=)[^&]+")
VAR3=$(echo "$POST_DATA" | grep -oP "(?<=VAR3=)[^&]+")
VAR4=$(echo "$POST_DATA" | grep -oP "(?<=VAR4=)[^&]+")

# Декодирование значений из URL-формата
VAR1=$(printf '%b' "${VAR1//%/\\x}")
VAR2=$(printf '%b' "${VAR2//%/\\x}")
VAR3=$(printf '%b' "${VAR3//%/\\x}")
VAR4=$(printf '%b' "${VAR4//%/\\x}")

# Константы для подключения к CI/CD
PROJECT_ID=XXXX
PIPELINE_TRIGGER_URL="https://example.com/api/v4/projects/$PROJECT_ID/trigger/pipeline"
JOB_LOG_URL="https://example.com/api/v4/projects/$PROJECT_ID/jobs"
TRIGGER_TOKEN="your-trigger-token"
ACCESS_TOKEN="your-access-token"

# Запуск пайплайна
pipeline_response=$(curl --silent -X POST \
      -F token="$TRIGGER_TOKEN" \
      -F ref=master \
      --form "variables[VAR1]=$VAR1" \
      --form "variables[VAR2]=$VAR2" \
      --form "variables[VAR3]=$VAR3" \
      --form "variables[VAR4]=$VAR4" \
      "$PIPELINE_TRIGGER_URL")

pipeline_id=$(echo "$pipeline_response" | jq -r '.id')

# Проверка ответа на запуск пайплайна
if [[ -z "$pipeline_id" || "$pipeline_id" == "null" ]]; then
  echo "<response><error>Ошибка получения ID пайплайна. Ответ: $pipeline_response</error></response>"
  exit 1
fi

# Задержка для завершения работы пайплайна
sleep 10  

# Получение ID job, связанного с пайплайном
job_id=$(curl --silent --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "$JOB_LOG_URL" | jq --argjson PIPELINE_ID "$pipeline_id" '.[] | select(.pipeline.id == $PIPELINE_ID) | .id' | head -n 1)

# Проверка на успешное получение job ID
if [[ -z "$job_id" || "$job_id" == "null" ]]; then
  echo "<response><error>Ошибка получения ID job. Проверьте доступность или авторизацию.</error></response>"
  exit 1
fi

# Получение полного лога выполнения job
job_log=$(curl --silent --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "$JOB_LOG_URL/$job_id/trace")

# Проверка на успешное получение лога
if [[ -z "$job_log" ]]; then
  echo "<response><error>Ошибка получения лога job или он пуст.</error></response>"
  exit 1
fi

# Экранирование недопустимых символов для XML
safe_job_log=$(echo "$job_log" | sed -e 's/&/&amp;/g' -e 's/</&lt;/g' -e 's/>/&gt;/g' -e 's/"/&quot;/g' -e 's/'\''/&apos;/g')

# Формирование XML ответа
echo "<response>"
echo "<action_message>Action completed successfully</action_message>"
echo "<job_log>$safe_job_log</job_log>"
echo "</response>"
