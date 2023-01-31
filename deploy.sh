#!/bin/bash
# настраиваем known_hosts и identity
# версия git в образе не позволяет задавать параметры подключения по ssh
echo SSH Configuration
mkdir $HOME/.ssh && chmod 700 $HOME/.ssh
cat ${SSH_BB_KEY_FILE} > $HOME/.ssh/id_ed25519
cat ssh_config/known_hosts > $HOME/.ssh/known_hosts
cat ssh_config/config > $HOME/.ssh/config
chmod 600 $HOME/.ssh/*

# линкуем vault.key для ansible-vault
echo Linking vault.key
ln -sf ${VAULT_KEY_FILE} vault.key

# запускаем ssh-agent
eval $(ssh-agent -s)

# добавляем креды для подключения по SSH
ssh-add ${SSH_ANSIBLE_KEY_FILE}

# устанавливаем зависимости плейбука
# echo Checkout Roles
# ansible-galaxy install -r requirements.yml --force  || exit 1

# запускаем плейбук
echo Run Playbook
ansible-playbook -i ${ANSIBLE_INVENTORY_FILE} "${ANSIBLE_EXTRA_ARGS}" site.yml
