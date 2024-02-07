package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

// Função para exibir mensagens formatadas
func displayMessage(message string) {
	fmt.Printf("[%s] %s\n", getTime(), message)
}

// Obter o tempo atual formatado
func getTime() string {
	return time.Now().Format("2006-01-02 15:04:05")
}

// Função para criar usuário
func createUser(username string) error {
	displayMessage(fmt.Sprintf("Criando usuário %s...", username))
	cmd := exec.Command("aws", "iam", "create-user", "--user-name", username)
	err := cmd.Run()
	if err != nil {
		displayMessage(fmt.Sprintf("Falha ao criar usuário %s: %v", username, err))
		return err
	}
	displayMessage(fmt.Sprintf("Usuário %s criado com sucesso.", username))
	return nil
}

// Função para adicionar usuário a um grupo existente
func addUserToGroup(username, groupname string) error {
	displayMessage(fmt.Sprintf("Adicionando usuário %s ao grupo %s...", username, groupname))
	cmd := exec.Command("aws", "iam", "add-user-to-group", "--user-name", username, "--group-name", groupname)
	err := cmd.Run()
	if err != nil {
		displayMessage(fmt.Sprintf("Falha ao adicionar usuário %s ao grupo %s: %v", username, groupname, err))
		return err
	}
	displayMessage(fmt.Sprintf("Usuário %s adicionado ao grupo %s com sucesso.", username, groupname))
	return nil
}

// Função para criar acesso ao console AWS com senha gerada automaticamente
func createConsoleAccess(username string) error {
	displayMessage(fmt.Sprintf("Adicionando acesso ao console AWS para o usuário %s...", username))
	// Implemente a lógica para gerar uma senha automaticamente
	// Use a biblioteca crypto/rand para gerar a senha
	password := generatePassword()

	// Chame o comando aws para criar o perfil de login com a senha gerada
	cmd := exec.Command("aws", "iam", "create-login-profile", "--user-name", username, "--password-reset-required", "--password", password)
	output, err := cmd.CombinedOutput()
	if err != nil {
		displayMessage(fmt.Sprintf("Falha ao criar acesso ao console AWS para o usuário %s: %v", username, err))
		return err
	}

	displayMessage(fmt.Sprintf("Senha gerada para o usuário %s: %s", username, password))
	displayMessage(fmt.Sprintf("Saída do comando AWS: %s", output))

	// Implemente a lógica para salvar as informações de acesso do console em um arquivo ou exibi-las na tela
	return nil
}

// Função para gerar uma senha aleatória
func generatePassword() string {
	// Implemente a lógica para gerar uma senha aleatória aqui
	// Use a biblioteca crypto/rand para gerar a senha
	return "senha_gerada_aleatoriamente"
}

func main() {
	// Crie um scanner para ler a entrada do usuário
	scanner := bufio.NewScanner(os.Stdin)

	// Solicitar nome do usuário
	fmt.Print("Insira o nome do usuário a ser criado: ")
	scanner.Scan()
	username := scanner.Text()

	// Criar usuário
	err := createUser(username)
	if err != nil {
		os.Exit(1)
	}

	// Listar grupos existentes
	fmt.Println("Grupos existentes:")
	cmd := exec.Command("aws", "iam", "list-groups", "--query", "Groups[*].GroupName", "--output", "text")
	output, err := cmd.Output()
	if err != nil {
		displayMessage(fmt.Sprintf("Erro ao listar grupos: %v", err))
		os.Exit(1)
	}

	groups := strings.Fields(string(output))
	for i, group := range groups {
		fmt.Printf("[%d]: %s\n", i, group)
	}

	// Solicitar número do grupo
	fmt.Print("Escolha um número para o grupo do usuário: ")
	scanner.Scan()
	groupNumberStr := scanner.Text()
	groupNumber, err := strconv.Atoi(groupNumberStr)
	if err != nil || groupNumber < 0 || groupNumber >= len(groups) {
		displayMessage("Número de grupo inválido.")
		os.Exit(1)
	}
	groupname := groups[groupNumber]

	// Adicionar usuário ao grupo
	err = addUserToGroup(username, groupname)
	if err != nil {
		os.Exit(1)
	}

	// Criar acesso ao console AWS
	err = createConsoleAccess(username)
	if err != nil {
		os.Exit(1)
	}
}
