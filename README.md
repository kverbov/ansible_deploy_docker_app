Playbook и конвейер конфигурации целевой среды для приложения backend.
# Запуск конвейера

Конвейер запускается из [Jenkins](https://jenkins.domain/job/department/job/PROVISION_backend/) через **Build with Parameters**.

## Параметры запуска

* **ENVIRONMENT**: целевое окружение, влияет на выбор целевого окружения в **ansible** плейбуке;
  * значение **по-умолчанию**: `test`;
* **APP_REGISTRY_PATH**: путь до **артефакта** приложения внутри **docker registry**;
* **ARTIFACT_VERSION**: версия **артефакта** приложения;
* **BRANCH**: ветка репозитория в **BitBucket**;
* **ANSIBLE_EXTRA_ARGS**: дополнительные параметры, передаваемые команде **ansible-playbook** при запуске;
  * значение **по-умолчанию**: `-v`.

## Переменные окружения
* **NEXUS_BASE_URL**: доменное имя хранилища **Nexus**;
* **BITBUCKET_BASE_URL**: базовый url **BitBucket**;
  * используется при формировании переменных **url** репозиториев;
  * используется при вызове **хуков**;
* **CREDENTIALS_ID**: логин и пароль **служебной** учетной записи;
* **BB_PROJECT**: 4-значный код команды в **BitBucket**;
* **PIPELINE_REPO**: название **текущего** репозитория в **BitBucket**;
* **ANSIBLE_VERSION**: часть тега docker **контейнера** в docker registry, относящаяся к версии **ansible**;
* **ANSIBLE_IMAGE**: полный **тег** docker контейнера **ansible** в docker registry;
* **PIPELINE_REPO_URL**: формирует полный url **текущего** репозитория;
* **BB_SSH_KEY**: **ssh-ключ** подключения к **BitBucket** для скачивания **ролей** из зависимостей плейбука, описанных в `requirements.yml`;
* **ANSIBLE_SSH_KEY**: **ключ**, который будет использован **ansible** для подключения к **целевым машинам**;
* **ANSIBLE_VAULT_KEY**: ключ для **ansible-vault**, используется для расшифровки `1_vault.yml` в `group_vars`;
* **POSTGRES_VERSION**: версия **Postgres** для деплоя;
* **REDIS_VERSION**: версия **Redis** для деплоя;

## Этапы конвейера (Stages)

Конвейер состоит из следующих этапов (**stages**):

* **Checkout: Pipeline**: производит **checkout** остального кода конвейера из BitBucket (**Jenkins** забирает только `Jenkinsfile`);
* **Deploy to Environment**: запускает выполнение **плейбука** деплоя приложения.

# Локальный запуск плейбука

## Подключение зеркала pypi.org в закрытом контуре

Необходимо **только** для локального запуска плейбука в **закрытом контуре** Росбанка.

* `pip config --user set global.index https://nexus.domain/repository/pypi-org-proxy/pypi`
* `pip config --user set global.index-url https://nexus.domain/repository/pypi-org-proxy/simple`
* `pip config --user set global.trsted-host nexus.domain`

## Подготовка локального окружения

* выполнить `python3 -m venv .venv` из **корня** проекта;
* активировать окружение через `source .venv/bin/activate` из **корня** проекта;
* обновить `pip` до последней версии через `pip install --upgrade pip`;
* установить `ansible` и все зависимости плейбука через `pip install -r requirements.txt`;
* установить внешние роли через `ansible-galaxy install -r requirements.yml`;
* по окончанию работы, виртуальное окружение можно будет деактивировать, выполнив `deactivate` в консоли.

Пример локального запуска:
* `ansible-playbook -i environments/test/inventory.yml site.yml`

## Работа с секретами

**Ansible** ожидает ключ для **ansbible-vault** в файле `vault.key` в **корне** проекта.

* Шифрование секретов: `ansible-vault encrypt environments/test/group_vars/front/1_vault.yml`
* Расшифровка секретов: `ansible-vault decrypt environments/test/group_vars/front/1_vault.yml`
* Просмотр секретов без манипуляции файлов: `ansible-vault view environments/test/group_vars/front/1_vault.yml`
* Редактирование секретов в редакторе по-умолчанию: `ansible-vault edit environments/test/group_vars/front/1_vault.yml`

Все файлы секретов должны быть зашифрованы перед совершением **commit**, в связи с чем не рекомендуется делать **decrypt** без надобности. Рекомендуется использовать **view** для просмотра и **edit** для редактирования.

# Описание плейбука

## Роли

Плейбук состоит из следующих ролей.

### Внутренние

* **deploy_backend**: выполняет следующие **таски**:
  * проверяет, что **директория проекта** существует;
  * рендерит **.env файлы** для сервисов проекта;
  * **рендерит** `docker-compose.yml` проекта из **шаблона**;
  * совершает **login** в **docker registry** под ТУЗ;
  * **запускает** приложение через `docker-compose`;

### Внешние

На данный момент плейбук не использует внешние роли.

## Теги

* **deploy_backend, deploy**: роль **docker_backend**.

Запуск плейбука без тегов запустит **все** таски, кроме тасков с тегом **never**.

## Структура каталогов

```
.
├── ansible.cfg                         # конфигурация Ansible
├── environments                        # целевые окружения
│   └── test                            # целевое окружение фронта в новом тестовом окружении
│       ├── group_vars                  # групповые переменные
│       │   ├── all                     # переменных для всех групп хостов
│       │   └── backend                 # переменные для хостов агентов
│       │       ├── 1_vault.yml         # зашифрованные секреты проекта
│       │       └── 2_secrets.yml       # присваивает значения секретов из 1_vault.yml рабочим переменным
│       └── inventory.yml               # параметры подключения к целевым хостам
├── playbooks                           # роли, разбитые по отдельным файлам плейбуков
├── requirements.txt                    # зависимости pip
├── requirements.yml                    # зависимости ansible-galaxy
├── roles                               # роли, локальные для плейбука
├── roles_imported                      # роли, устанавливаемые через ansible-galaxy
├── site.yml                            # глобальный мета-плейбук, импортирующий остальные плейбуки
└── vault.key                           # ключ для ansible-vault
```
