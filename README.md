# gitlabAPI_Bash

Этот Bash-скрипт предназначен для обработки данных POST-запроса, запуска пайплайнов в CI/CD системе и получения их результатов. Он взаимодействует с API системы для управления пайплайнами и извлекает данные о выполнении заданий (jobs). Используется по следующему алгоритму:

Создается ссылка cgi на httpd или Apache (Пример: Example.com/gitAPI.sh)
Размещаем скрипт в /var/www/html/cgi-bin/script.sh
Подготавливаем конфиг файл

         ScriptAlias /cgi-bin/ /var/www/cgi-bin/
         <Directory "/var/www/cgi-bin/">
           AllowOverride None
           Options +ExecCGI
           Require all granted
         </Directory>
         

Отправляется Curl запрос следующего формата:
curl -X POST https://(Адрес веб сервера на котором опубликовали скрипт)/cgi-bin/script.sh -H "Content-Type: application/json" --data "VAR1=*&VAR2=*&VAR3=3600&VAR4=*"
