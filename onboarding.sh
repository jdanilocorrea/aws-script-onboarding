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


function mfa_attach_user_policy {
  local USER_NAME="$1"
  local AWS_CONSOLE="$2"
  local ARN_AWS_IAM_POLICY

  
  ARN_AWS_IAM_POLICY=$(awslocal iam list-policies --query "Policies[?PolicyName==\`SelfManageMFADevice\`].Arn" --output text)

  if [[ "$AWS_CONSOLE" == "pnb-hml" || "$AWS_CONSOLE" == "pnb-prd" ]]; then
    awslocal iam attach-user-policy --user-name "$USER_NAME" --policy-arn "$ARN_AWS_IAM_POLICY"
    display_message "A política 'SelfManageMFADevice' foi adicionada ao usuário $USER_NAME - $AWS_CONSOLE com sucesso."
  else
    display_message "Não foi possível adicionar a política 'SelfManageMFADevice' - Console $AWS_CONSOLE não reconhecido."
  fi
}




# Função para buscar informações de acesso ao console
function get_console_access {
  ACCOUNT_ALIAS=$(awslocal iam list-account-aliases --query 'AccountAliases[0]' --output text)

  case "$ACCOUNT_ALIAS" in
    "pnb-hml")
      CONSOLE_URL="https://pnb-hml.signin.aws.amazon.com/console"
      ;;
    "pnb-prd")
      CONSOLE_URL="https://pnb-prd.signin.aws.amazon.com/console"
      ;;
    "None")
      CONSOLE_URL="https://None.signin.aws.amazon.com/console"
      ;;  
    # Adicione mais casos conforme necessário
    *)
      display_message "Console Access não reconhecido para alias '$ACCOUNT_ALIAS'."
      return
      ;;
  esac

  display_message "Gerar informações arquivo 'console-access' usuário $1 - $ACCOUNT_ALIAS."

  {
    echo "AWS-$ACCOUNT_ALIAS"
    echo ""
    echo "$CONSOLE_URL"
    echo ""
    echo "usuário: $1"
    echo ""
    echo "senha: $2"
    echo "----------------------------------------------------------------"
    echo ""
  } >> console-access
}


# Função para criar acesso ao console AWS com senha gerada automaticamente
function create_console_access {
  echo "------------CREATE CONSOLE ACCESS--------------------------"
  display_message "Adicionando acesso ao console AWS para o usuário $1..."
  AUTOSENHA=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | fold -w 1 | shuf | head -n 1)$(openssl rand -base64 11)
  LOGIN_PROFILE=$(awslocal iam create-login-profile --user-name "$1" --password-reset-required --password "$AUTOSENHA" 2>/dev/null)
  if [ -n "$LOGIN_PROFILE" ]; then
    display_message "Senha gerada para o usuário $1 com sucesso."

    ACCOUNT_ALIAS=$(awslocal iam list-account-aliases --query 'AccountAliases[0]' --output text)
    CONSOLE_URL="https://$ACCOUNT_ALIAS.signin.aws.amazon.com/console"
    USER_CONSOLE=$(echo "$LOGIN_PROFILE" | jq -r '.LoginProfile.UserName')
    # PASSWORD_CONSOLE=$(echo "$LOGIN_PROFILE" | jq -r '.LoginProfile.Password')
    
    echo "============================================"
    echo "=============AWS CONSOLE ENABLED============"
    echo "============================================"
    echo ""
    echo "      URL:$CONSOLE_URL" 
    echo "      USER: $USER_CONSOLE"
    echo "      PASSWORD: $AUTOSENHA"
    echo ""              
    echo "============================================"

    # Faça o que precisar com o token de autenticação, como abrir o navegador com o URL do console
    # open "$CONSOLE_URL  
       
    # display_and_download "$CONSOLE_URL" "$USER_CONSOLE" "$AUTOSENHA"
    get_console_access "$USER_CONSOLE" "$AUTOSENHA"
    mfa_attach_user_policy "$1" "$ACCOUNT_ALIAS"

  else
    display_message "Falha ao gerar senha para o usuário $1."
  fi
}



# Função para buscar informações das crendênciais
function get-credentials {

  ACCOUNT_ALIAS=$(awslocal iam list-account-aliases --query 'AccountAliases[0]' --output text)
  CONSOLE_URL="$ACCOUNT_ALIAS"
  
  if [[ "$CONSOLE_URL" == "pnb-hml" ]]; then

      display_message "Gerar informações arquivo 'credentials' usuário $1 - pnb-hml."  
      {
      echo "[default]" 
      echo "aws_access_key_id = $1" 
      echo "aws_secret_access_key = $2" 
      echo "" 

      echo "[psd-hml]" 
      echo "aws_access_key_id = $1" 
      echo "aws_secret_access_key = $2" 
      echo "" 

      echo "[pix-hml]" 
      echo "aws_access_key_id = $1" 
      echo "aws_secret_access_key = $2" 
      echo "" 
      } >> credentials

  elif [[ "$CONSOLE_URL" == "pnb-prd" ]]; then

      display_message "Gerar informações arquivo 'credentials' usuário $1 - pnb-prd."  
      {
      echo "[psd-prd]" 
      echo "aws_access_key_id = $1" 
      echo "aws_secret_access_key = $2" 
      echo "" 

      echo "[pix-prd]" 
      echo "aws_access_key_id = $1" 
      echo "aws_secret_access_key = $2" 
      echo "" 
      } >> credentials

  elif [[ "$CONSOLE_URL" == "None" ]]; then

      display_message "Gerar informações arquivo 'credentials' usuário $1 - pnb-prd."  
      {
      echo "[none]" 
      echo "aws_access_key_id = $1" 
      echo "aws_secret_access_key = $2" 
      echo "" 
      } >> credentials    

  else

      # Adicione outra condição conforme necessário
      echo "Console URL não reconhecido."

  fi
}


# Função para criar acesso ao AWS CLI para o usuário
function create_cli_access {
  echo "------------CREATE AWS-CLI ACCESS---------------------------"
  display_message "Criando acesso ao AWS CLI para o usuário $1..."
  
  # Chama o comando uma vez e armazena o resultado nas variáveis
  ACCESS_KEY_ID=$(awslocal iam create-access-key --user-name "$1" --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text 2>/dev/null)

  if [ -n "$ACCESS_KEY_ID" ]; then
    # Extrai a access key e a secret key do resultado
    ACCESS_KEY=$(echo "$ACCESS_KEY_ID" | cut -f1)
    SECRET_KEY=$(echo "$ACCESS_KEY_ID" | cut -f2)

    # Configura as credenciais no perfil do AWS CLI
    if awslocal configure set aws_access_key_id "$ACCESS_KEY" --profile "$1" && \
       awslocal configure set aws_secret_access_key "$SECRET_KEY" --profile "$1"; then
        display_message "Chaves de acesso do AWS CLI configuradas com sucesso."
      
         echo "============================================"
         echo "=============AWS CLI ENABLED================"
         echo "============================================"
         echo ""
         echo "      ACCESS KEY: $ACCESS_KEY" 
         echo "      SECRET KEY: $SECRET_KEY"
         echo ""              
         echo "============================================"      

        #  display_cli_and_download "$1" "$ACCESS_KEY" "$SECRET_KEY"
         get-credentials "$ACCESS_KEY" "$SECRET_KEY"

    else
      display_message "Falha ao configurar chaves de acesso do AWS CLI para o usuário $1."
    fi
  else
    display_message "Falha ao criar chaves de acesso do AWS CLI para o usuário $1."
  fi
}


# Passo 1: Solicitar informações do usuário
echo -n "Insira o nome do usuário a ser criado: "
read -r USUARIO

# # Passo 2: Listar grupos existentes
# echo "Grupos existentes:"
# read -r -a groups <<<"$(awslocal iam list-groups --query 'Groups[*].GroupName' --output text)"
# #mapfile -t groups < <(awslocal iam list-groups --query 'Groups[*].GroupName' --output text)
# #groups=($(awslocal iam list-groups --query 'Groups[*].GroupName' --output text))
# for ((i = 0; i <= ${#groups[@]}; i++)); do
#     echo "[$i]: ${groups[$i]}"
# done
# echo -n "Escolha um número para o grupo do usuário: "
# read -r group_number


# Passo 2: Listar grupos existentes
echo "Grupos existentes:"
read -r -a groups <<<"$(awslocal iam list-groups --query 'Groups[*].GroupName' --output text)"
#mapfile -t groups < <(awslocal iam list-groups --query 'Groups[*].GroupName' --output text)
#groups=($(awslocal iam list-groups --query 'Groups[*].GroupName' --output text))
for ((i = 0; i <= ${#groups[@]}; i++)); do
    echo "[$i]: ${groups[$i]}"
done
echo -n "Escolha um número para o grupo do usuário: "
read -r group_number

# Verificar se a opção selecionada é válida
if [[ "$group_number" =~ ^[0-9]+$ ]] && (( group_number >= 0 && group_number <= ${#groups[@]} )); then
    # Obter o nome do grupo com base no número escolhido
    GRUPO=${groups[$group_number]}
else
    echo "Opção inválida selecionada. Por favor, escolha um número válido."
    return 
fi





echo "Escolha uma opção:"
echo "[1] default"
echo "[2] psd-hml"
echo "[3] psd-prd"
echo "[4] localstack"
# Lê a escolha do usuário
echo -n "Digite o número da sua escolha: "
read -r environment_choice

# Verifica a escolha do usuário
case $environment_choice in
    1) environment="default" ;;
    2) environment="psd-hml" ;;
    3) environment="psd-prd" ;;
    4) environment="localstack" ;;
    *) echo "Opção inválida. Saindo."; return ;;
esac

echo "Você escolheu a opção: $environment"

export AWS_DEFAULT_PROFILE="$environment"

echo "Pressione Enter para continuar ou 'c' para cancelar: \c"
read -r input


# Verificar a entrada do usuário
if [[ "$input" == "c" ]]; then
    echo "Operação cancelada pelo usuário."
    return  # Sai do script com código de erro 1 (ou o código que você preferir)
else

# Executar as funções
create_user "$USUARIO"
add_user_to_group "$USUARIO" "$GRUPO"
echo "Wait to..."
sleep 5
create_console_access "$USUARIO"
echo "Wait to..."
sleep 5
create_cli_access "$USUARIO"

echo ""
echo ""
echo "===================================================="
echo "============INFO RESULTS============================"
echo ""
echo "        Acesso ao Console AWS"
echo "        ---------------------"
echo ""
echo -e "Usuário: $USUARIO\nSenha: $LOGIN_PROFILE\nGrupo: $GRUPO"
echo ""
# Títulos para Chaves de Acesso
echo "       Chaves de Acesso AWS CLI"
echo "       ------------------------"
echo ""
# Listar Access Key ID associada ao usuário
awslocal iam list-access-keys --user-name "$USUARIO" --query 'AccessKeyMetadata[].[AccessKeyId, Status, CreateDate]' --output text | awk '{printf("[%s : %s]\n", "Access Key ID", $1)}'
unset AWS_DEFAULT_PROFILE

fi