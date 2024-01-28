#!/usr/bin/env bash


echo "List Users"
echo "------------"

# Obtém a lista de usuários com ARN e grupos associados como um array
USERS=($(aws iam list-users --query 'Users[*].[UserName, Arn, CreateDate]' --output text))

# Itera sobre cada usuário
for ((i=0; i<${#USERS[@]}; i+=3)); do
    echo -e "\nDate create: ${USERS[i+3]}"
    echo "User:  ${USERS[i+1]}"
    echo "ARN: ${USERS[i+2]}"

    # Lista os grupos associados ao usuário
    GROUPS=($(aws iam list-groups-for-user --user-name ${USERS[i+1]} --query 'Groups[].GroupName' --output text))

    # Verifica se há grupos associados
    if [ ${#GROUPS[@]} -gt 0 ]; then
        echo "Groups:[ ${GROUPS[@]} ]"
    else
        echo "No groups associated."
    fi

    echo "---------------------------"
done