#!/usr/bin/env bash


# Função para exibir mensagens formatadas
function display_message {
  echo -e "[$(date)] $1"
}

# Função para criar usuário
function create_user {
  display_message "Criando usuário $1..."
  if awslocal iam create-user --user-name "$1" 2>/dev/null; then
    display_message "Usuário $1 criado com sucesso."
  else
    display_message "Falha ao criar usuário $1."
  fi
}

# Função para adicionar usuário a um grupo existente
function add_user_to_group {
  display_message "Adicionando usuário $1 ao grupo $2..."
  if awslocal iam add-user-to-group --user-name "$1" --group-name "$2" 2>/dev/null; then
    display_message "Usuário $1 adicionado ao grupo $2 com sucesso."
  else
    display_message "Falha ao adicionar usuário $1 ao grupo $2."
  fi
}

# Função para criar acesso ao console AWS com senha gerada automaticamente
function create_console_access {
  display_message "Adicionando acesso ao console AWSlocal para o usuário $1..."
  AUTOSENHA=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | fold -w 1 | shuf | head -n 1)$(openssl rand -base64 11)
  SENHA=$(awslocal iam create-login-profile --user-name "$1" --password-reset-required --password "$AUTOSENHA" 2>/dev/null | jq -r '.LoginProfile.Password')
  if [ -n "$SENHA" ]; then
    display_message "Senha gerada para o usuário $1 com sucesso."
    echo "$SENHA"
  else
    display_message "Falha ao gerar senha para o usuário $1."
  fi
}

# Função para exibir acesso do usuário e baixar arquivo CSV
function display_and_download {
  display_message "Exibindo acesso e baixando arquivo CSV..."
  echo -e "Acesso ao Console AWSlocal:"
  echo -e "Usuário: $1\nSenha: $2\nGrupo: $3"
  if awslocal iam list-access-keys --user-name "$1" 2>/dev/null; then
    display_message "Chaves de acesso listadas com sucesso."
  else
    display_message "Falha ao listar chaves de acesso para o usuário $1."
  fi
  if awslocal iam create-login-profile --user-name "$1" --password-reset-required --query 'LoginProfile.[UserName, LoginProfile.Password, LoginProfile.CreateDate]' --output csv > usuario_acesso.csv 2>/dev/null; then
    display_message "Arquivo CSV gerado com sucesso."
  else
    display_message "Falha ao gerar arquivo CSV para o usuário $1."
  fi
}

# Função para criar acesso ao AWS CLI para o usuário
function create_cli_access {
  display_message "Criando acesso ao AWSlocal CLI para o usuário $1..."
  if awslocal configure set aws_access_key_id "$(awslocal iam create-access-key --user-name "$1" --query 'AccessKey.[AccessKeyId]' --output text 2>/dev/null)" --profile "$1" && \
     awslocal configure set aws_secret_access_key "$(awslocal iam create-access-key --user-name "$1" --query 'AccessKey.[SecretAccessKey]' --output text 2>/dev/null)" --profile "$1"; then
    display_message "Chaves de acesso do AWS CLI configuradas com sucesso."
  else
    display_message "Falha ao configurar chaves de acesso do AWS CLI para o usuário $1."
  fi
}

# Função para exibir acesso ao AWS CLI e baixar arquivo CSV
function display_cli_and_download {
  display_message "Exibindo acesso ao AWSlocal CLI e baixando arquivo CSV..."
  echo -e "Acesso ao AWSlocal CLI:"
  echo -e "Usuário: $1\nChave de Acesso: $(awslocal configure get aws_access_key_id --profile "$1" 2>/dev/null)\nChave Secreta: $(awslocal configure get aws_secret_access_key --profile "$1" 2>/dev/null)"
  if awslocal configure list-profiles --output table --profile "$1" > usuario_acesso_cli.csv 2>/dev/null; then
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
SENHA=$(create_console_access "$USUARIO")
display_and_download "$USUARIO" "$SENHA" "$GRUPO"
create_cli_access "$USUARIO"
display_cli_and_download "$USUARIO"

# Exibir acesso do usuário e baixar arquivo CSV
display_message "Exibindo acesso do usuário e baixando arquivo CSV..."
echo -e "Acesso ao Console AWSlocal:"
echo -e "Usuário: $USUARIO\nSenha: $SENHA\nGrupo: $GRUPO"

# Títulos para Chaves de Acesso
echo -e "\nChaves de Acesso:"
# Listar Access Key ID associada ao usuário
awslocal iam list-access-keys --user-name "$USUARIO" --query 'AccessKeyMetadata[].[AccessKeyId, Status, CreateDate]' --output text | awk '{printf("[%s : %s]\n", "Access Key ID", $1)}'
























# #!/usr/bin/env bash

# # Função para exibir mensagens formatadas
# function display_message {
#   echo -e "[$(date)] $1"
# }

# # Função para criar usuário
# function create_user {
#   display_message "Criando usuário $1..."
#   awslocal iam create-user --user-name "$1" 2>/dev/null
# }

# # Função para adicionar usuário a um grupo existente
# function add_user_to_group {
#   display_message "Adicionando usuário $1 ao grupo $2..."
#   awslocal iam add-user-to-group --user-name "$1" --group-name "$2" 2>/dev/null
# }

# # Função para criar acesso ao console AWS com senha gerada automaticamente
# function create_console_access {
#   display_message "Adicionando acesso ao console AWSlocal para o usuário $1..."
#   SENHA=$(awslocal iam create-login-profile --user-name "$1" --password-reset-required 2>/dev/null | jq -r '.LoginProfile.Password')
#   echo "$SENHA"
# }

# # Função para exibir acesso do usuário e baixar arquivo CSV
# function display_and_download {
#   display_message "Exibindo acesso e baixando arquivo CSV..."
#   echo -e "Acesso ao Console AWSlocal:"
#   echo -e "Usuário: $1\nSenha: $2\nGrupo: $3"
#   awslocal iam list-access-keys --user-name "$1" 2>/dev/null
#   awslocal iam create-login-profile --user-name "$1" --password-reset-required --query 'LoginProfile.[UserName, LoginProfile.Password, LoginProfile.CreateDate]' --output csv > usuario_acesso.csv 2>/dev/null
# }

# # Função para criar acesso ao AWS CLI para o usuário
# function create_cli_access {
#   display_message "Criando acesso ao AWSlocal CLI para o usuário $1..."
#   awslocal configure set aws_access_key_id "$(awslocal iam create-access-key --user-name "$1" --query 'AccessKey.[AccessKeyId]' --output text 2>/dev/null)" --profile "$1"
#   awslocal configure set aws_secret_access_key "$(awslocal iam create-access-key --user-name "$1" --query 'AccessKey.[SecretAccessKey]' --output text 2>/dev/null)" --profile "$1"
# }

# # Função para exibir acesso ao AWS CLI e baixar arquivo CSV
# function display_cli_and_download {
#   display_message "Exibindo acesso ao AWSlocal CLI e baixando arquivo CSV..."
#   echo -e "Acesso ao AWSlocal CLI:"
#   echo -e "Usuário: $1\nChave de Acesso: $(awslocal configure get aws_access_key_id --profile "$1" 2>/dev/null)\nChave Secreta: $(awslocal configure get aws_secret_access_key --profile "$1" 2>/dev/null)"
#   awslocal configure list-profiles --output table --profile "$1" > usuario_acesso_cli.csv 2>/dev/null
# }

# # Verificar número de argumentos
# if [ "$#" -ne 2 ]; then
#     echo "Uso: $0 <USUARIO> <GRUPO>"
#     exit 1
# fi

# # Parâmetros do script
# USUARIO="$1"
# GRUPO="$2"

# # Executar as funções
# create_user "$USUARIO"
# add_user_to_group "$USUARIO" "$GRUPO"
# SENHA=$(create_console_access "$USUARIO")
# display_and_download "$USUARIO" "$SENHA" "$GRUPO"
# create_cli_access "$USUARIO"
# display_cli_and_download "$USUARIO"

# # Exibir acesso do usuário e baixar arquivo CSV
# display_message "Exibindo acesso do usuário e baixando arquivo CSV..."
# echo -e "Acesso ao Console AWSlocal:"
# echo -e "Usuário: $USUARIO\nSenha: $SENHA\nGrupo: $GRUPO"

# # Títulos para Chaves de Acesso
# echo -e "\nChaves de Acesso:"
# # Listar Access Key ID associada ao usuário
# awslocal iam list-access-keys --user-name "$USUARIO" --query 'AccessKeyMetadata[].[AccessKeyId, Status, CreateDate]' --output text 2>/dev/null | awk '{printf("[%s : %s]\n", "Access Key ID", $1)}'

















# #!/usr/bin/env bash

# # Função para exibir mensagens formatadas
# function display_message {
#   echo -e "[$(date)] $1"
# }

# # Função para criar usuário
# function create_user {
#   display_message "Criando usuário $1..."
#   awslocal iam create-user --user-name "$1"
# }

# # Função para adicionar usuário a um grupo existente
# function add_user_to_group {
#   display_message "Adicionando usuário $1 ao grupo $2..."
#   awslocal iam add-user-to-group --user-name "$1" --group-name "$2"
# }

# # Função para criar acesso ao console AWS com senha gerada automaticamente
# function create_console_access {
#   display_message "Adicionando acesso ao console AWSlocal para o usuário $1..."
#   SENHA=$(awslocal iam create-login-profile --user-name "$1" --password-reset-required | jq -r '.LoginProfile.Password')
#   echo "$SENHA"
# }

# # Função para exibir acesso do usuário e baixar arquivo CSV
# function display_and_download {
#   display_message "Exibindo acesso e baixando arquivo CSV..."
#   echo -e "Acesso ao Console AWSlocal:"
#   echo -e "Usuário: $1\nSenha: $2\nGrupo: $3"
#   awslocal iam list-access-keys --user-name "$1"
#   awslocal iam create-login-profile --user-name "$1" --password-reset-required --query 'LoginProfile.[UserName, LoginProfile.Password, LoginProfile.CreateDate]' --output csv > usuario_acesso.csv
# }

# # Função para criar acesso ao AWS CLI para o usuário
# function create_cli_access {
#   display_message "Criando acesso ao AWSlocal CLI para o usuário $1..."
#   awslocal configure set aws_access_key_id "$(awslocal iam create-access-key --user-name "$1" --query 'AccessKey.[AccessKeyId]' --output text)" --profile "$1"
#   awslocal configure set aws_secret_access_key "$(awslocal iam create-access-key --user-name "$1" --query 'AccessKey.[SecretAccessKey]' --output text)" --profile "$1"
# }

# # Função para exibir acesso ao AWS CLI e baixar arquivo CSV
# function display_cli_and_download {
#   display_message "Exibindo acesso ao AWSlocal CLI e baixando arquivo CSV..."
#   echo -e "Acesso ao AWSlocal CLI:"
#   echo -e "Usuário: $1\nChave de Acesso: $(awslocal configure get aws_access_key_id --profile "$1")\nChave Secreta: $(awslocal configure get aws_secret_access_key --profile "$1")"
#   awslocal configure list-profiles --output table --profile "$1" > usuario_acesso_cli.csv
# }

# # Verificar número de argumentos
# if [ "$#" -ne 2 ]; then
#     echo "Uso: $0 <USUARIO> <GRUPO>"
#     exit 1
# fi

# # Parâmetros do script
# USUARIO="$1"
# GRUPO="$2"

# # Executar as funções
# create_user "$USUARIO"
# add_user_to_group "$USUARIO" "$GRUPO"
# SENHA=$(create_console_access "$USUARIO")
# display_and_download "$USUARIO" "$SENHA" "$GRUPO"
# create_cli_access "$USUARIO"
# display_cli_and_download "$USUARIO"

# # Exibir acesso do usuário e baixar arquivo CSV
# display_message "Exibindo acesso do usuário e baixando arquivo CSV..."
# echo -e "Acesso ao Console AWSlocal:"
# echo -e "Usuário: $USUARIO\nSenha: $SENHA\nGrupo: $GRUPO"

# # Títulos para Chaves de Acesso
# echo -e "\nChaves de Acesso:"
# # Listar Access Key ID associada ao usuário
# awslocal iam list-access-keys --user-name "$USUARIO" --query 'AccessKeyMetadata[].[AccessKeyId, Status, CreateDate]' --output text | awk '{printf("[%s : %s]\n", "Access Key ID", $1)}'





