#!/usr/bin/env bash


# Função para exibir mensagens formatadas
function display_message {
  echo "[$(date)] $1"
}

# Função para criar usuário e adicionar a um grupo
function create_user_and_add_to_group {
  display_message "Criando usuário $1 e adicionando ao grupo $2..."
  if awslocal iam create-user --user-name "$1" && awslocal iam add-user-to-group --user-name "$1" --group-name "$2"; then
    display_message "Usuário $1 criado e adicionado ao grupo $2 com sucesso."
  else
    display_message "Falha ao criar usuário $1 ou adicionar ao grupo $2."
    # exit 1
  fi
}

# Função para habilitar acesso ao console e criar senha automática
function enable_console_access {
  display_message "Habilitando acesso ao console AWS para o usuário $1..."
  AUTOSENHA=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | fold -w 1 | shuf | head -n 1)$(openssl rand -base64 11)
  if SENHA=$(awslocal iam create-login-profile --user-name "$1" --password-reset-required --password "$AUTOSENHA" | jq -r '.LoginProfile.Password'); then
    display_message "Acesso ao console AWS habilitado com sucesso."
    save_csv "$1" "$AUTOSENHA"
    sleep 3 # Aguarde 10 segundos antes de continuar
    display_user_info
  else
    display_message "Falha ao habilitar acesso ao console AWS para o usuário $1."
    # exit 1
  fi
}


# Função para baixar arquivo CSV
function function save_csv {
  echo "Saving info CSV..."
  echo "" > usuario_acesso.csv
  echo -e "\nCreate date: $(date)" >> usuario_acesso.csv
  echo "Arn: $(awslocal iam get-user --user-name "$1" --query 'User.Arn' --output text)" >> usuario_acesso.csv
  echo "User: $1" >> usuario_acesso.csv
  echo "Groups: $(awslocal iam list-groups-for-user --user-name "$1" --query 'Groups[].GroupName' --output text)" >> usuario_acesso.csv
  echo "--------------------------------" >> usuario_acesso.csv
  echo -e "Console AWS:" >> usuario_acesso.csv
  echo "User: $1" >> usuario_acesso.csv
  echo "Password: $2" >> usuario_acesso.csv
  echo "--------------------------------" >> usuario_acesso.csv
}

Função para exibir informações detalhadas do usuário
function display_user_info {
  cat usuario_acesso.csv
}

# Verificar número de argumentos
if [ "$#" -ne 2 ]; then
  echo "Uso: $0 <USUARIO> <GRUPO>"
  # exit 1
fi

# Parâmetros do script
USUARIO="$1"
GRUPO="$2"

# Executar as funções
create_user_and_add_to_group "$USUARIO" "$GRUPO"
enable_console_access "$USUARIO"




