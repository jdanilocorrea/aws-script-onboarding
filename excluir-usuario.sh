#!/usr/bin/env bash


# Função para remover um usuário de todos os grupos
remove_user_from_all_groups() {
    local username="$1"
    local groups=($(awslocal iam list-groups-for-user --user-name "$username" --query 'Groups[*].GroupName' --output text))
    for group in "${groups[@]}"; do
        awslocal iam remove-user-from-group --user-name "$username" --group-name "$group"
    done
}

# Função para listar e desanexar políticas de usuário
detach_user_policies() {
    local username="$1"
    local policies=($(awslocal iam list-attached-user-policies --user-name "$username" --query 'AttachedPolicies[*].PolicyArn' --output text))
    for policy in "${policies[@]}"; do
        awslocal iam detach-user-policy --user-name "$username" --policy-arn "$policy"
    done
}

# Função para excluir chaves de acesso do usuário
delete_access_keys() {
    local username="$1"
    local access_keys=($(awslocal iam list-access-keys --user-name "$username" --query 'AccessKeyMetadata[*].AccessKeyId' --output text))
    for access_key in "${access_keys[@]}"; do
        awslocal iam delete-access-key --user-name "$username" --access-key-id "$access_key"
    done
}

# Função para desativar ou excluir a senha do usuário
delete_login_profile() {
    local username="$1"
    awslocal iam delete-login-profile --user-name "$username"
}

# Função principal para excluir o usuário
delete_user() {
    local username="$1"

    # Remover usuário de todos os grupos
    remove_user_from_all_groups "$username"

    # Desanexar políticas
    detach_user_policies "$username"

    # Excluir chaves de acesso
    delete_access_keys "$username"

    # Desativar ou excluir a senha
    delete_login_profile "$username"

    # Excluir o usuário
    awslocal iam delete-user --user-name "$username"
}

# Variáveis (ajuste conforme necessário)
username="$1"

# Executar a exclusão do usuário
delete_user "$username"

echo "Usuário '$username' excluído com sucesso."
