#!/usr/bin/env bash


# Função para exibir mensagens formatadas
function display_message {
  echo -e "[$(date)] $1"
}

# Função para criar usuário
function create_user {
  display_message "Criando usuário $1..."
  if aws iam create-user --user-name "$1" 2>/dev/null; then
    
    display_message "Usuário $1 criado com sucesso."
  else
    display_message "Falha ao criar usuário $1."
  fi
}

# Função para adicionar usuário a um grupo existente
function add_user_to_group {
  display_message "Adicionando usuário $1 ao grupo $2..."
  if aws iam add-user-to-group --user-name "$1" --group-name "$2" 2>/dev/null; then
    display_message "Usuário $1 adicionado ao grupo $2 com sucesso."
  else
    display_message "Falha ao adicionar usuário $1 ao grupo $2."
  fi
}

# Função para exibir acesso do usuário e baixar arquivo
function display_and_download {
  echo "-------------------DOWNLOAD-------------------------------"
  display_message "Exibindo acesso e criando arquivo..."
  echo -e "Acesso ao Console AWS:"
  echo -e "Usuário: $1\nSenha: $2\nGrupo: $3"
  if aws iam list-access-keys --user-name "$1" 2>/dev/null; then
    display_message "Chaves de acesso listadas com sucesso."
  else
    display_message "Falha ao listar chaves de acesso para o usuário $1."
  fi
  if aws iam create-login-profile --user-name "$1" --password-reset-required --query 'LoginProfile.[UserName, LoginProfile.Password, LoginProfile.CreateDate]' --output csv > usuario_acesso.csv 2>/dev/null; then
    display_message "Arquivo CSV gerado com sucesso."
  else
    display_message "Falha ao gerar arquivo CSV para o usuário $1."
  fi
  echo "-----------------------------------------------------------"
}

# Função para criar acesso ao console AWS com senha gerada automaticamente
function create_console_access {
  display_message "Adicionando acesso ao console AWS para o usuário $1..."
  AUTOSENHA=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | fold -w 1 | shuf | head -n 1)$(openssl rand -base64 11)
  LOGIN_PROFILE=$(aws iam create-login-profile --user-name "$1" --password-reset-required --password "$AUTOSENHA" 2>/dev/null)
  if [ -n "$LOGIN_PROFILE" ]; then
    display_message "Senha gerada para o usuário $1 com sucesso."
    USER_CONSOLE=$(echo "$LOGIN_PROFILE" | jq -r '.LoginProfile.UserName')
    PASSWORD_CONSOLE=$(echo "$LOGIN_PROFILE" | jq -r '.LoginProfile.Password')
    echo "============================================"
    echo "=============AWS CONSOLE ENABLED============"
    echo "============================================"
    echo "==========Usuário: $USER_CONSOLE============"
    echo "==========Senha: $PASSWORD_CONSOLE=========="
    echo "============================================"
    display_and_download "$1" "$AUTOSENHA" "$2"
  else
    display_message "Falha ao gerar senha para o usuário $1."
  fi
}

# Função para criar acesso ao AWS CLI para o usuário
function create_cli_access {
  display_message "Criando acesso ao AWS CLI para o usuário $1..."
  
  # Chama o comando uma vez e armazena o resultado nas variáveis
  ACCESS_KEY_ID=$(aws iam create-access-key --user-name "$1" --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text 2>/dev/null)

  if [ -n "$ACCESS_KEY_ID" ]; then
    # Extrai a access key e a secret key do resultado
    ACCESS_KEY=$(echo "$ACCESS_KEY_ID" | cut -f1)
    SECRET_KEY=$(echo "$ACCESS_KEY_ID" | cut -f2)

    # Configura as credenciais no perfil do AWS CLI
    if aws configure set aws_access_key_id "$ACCESS_KEY" --profile "$1" && \
       aws configure set aws_secret_access_key "$SECRET_KEY" --profile "$1"; then
      display_message "Chaves de acesso do AWS CLI configuradas com sucesso."
    else
      display_message "Falha ao configurar chaves de acesso do AWS CLI para o usuário $1."
    fi
  else
    display_message "Falha ao criar chaves de acesso do AWS CLI para o usuário $1."
  fi
}

# Função para exibir acesso ao AWS CLI e baixar arquivo CSV
function display_cli_and_download {
  display_message "Exibindo acesso ao AWS CLI e baixando arquivo..."
  echo -e "Acesso ao AWS CLI:"
  echo -e "Usuário: $1\nChave de Acesso: $(aws configure get aws_access_key_id --profile "$1" 2>/dev/null)\nChave Secreta: $(aws configure get aws_secret_access_key --profile "$1" 2>/dev/null)"
  if aws configure list-profiles --output table --profile "$1" > usuario_acesso_cli.csv 2>/dev/null; then
    display_message "Arquivo CSV do AWS CLI gerado com sucesso."
  else
    display_message "Falha ao gerar arquivo CSV do AWS CLI para o usuário $1."
  fi
}

# Verificar número de argumentos
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <USUARIO> <GRUPO>"
    exit 1
fi

# Parâmetros do script
USUARIO="$1"
GRUPO="$2"

# Executar as funções
create_user "$USUARIO"
add_user_to_group "$USUARIO" "$GRUPO"
create_console_access "$USUARIO" "$GRUPO"
echo "wait to..."
sleep 5ource
create_cli_access "$USUARIO"
display_cli_and_download "$USUARIO"

# Exibir acesso do usuário e baixar arquivo CSV
display_message "Exibindo acesso do usuário e baixando arquivo CSV..."
echo -e "Acesso ao Console AWS:"
echo -e "Usuário: $USUARIO\nSenha: $LOGIN_PROFILE\nGrupo: $GRUPO"

# Títulos para Chaves de Acesso
echo -e "\nChaves de Acesso:"
# Listar Access Key ID associada ao usuário
aws iam list-access-keys --user-name "$USUARIO" --query 'AccessKeyMetadata[].[AccessKeyId, Status, CreateDate]' --output text | awk '{printf("[%s : %s]\n", "Access Key ID", $1)}'




