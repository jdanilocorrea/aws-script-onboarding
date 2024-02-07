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

// Configurações
const (
	awsCLICommand = "aws"
)

// Logger é uma interface para registro de mensagens.
type Logger interface {
	Log(message string)
}

// ConsoleLogger é uma implementação de Logger que imprime mensagens no console.
type ConsoleLogger struct{}

// Log imprime a mensagem no console.
func (l ConsoleLogger) Log(message string) {
	fmt.Printf("[%s] %s\n", getTime(), message)
}

// User representa um usuário do sistema.
type User struct {
	Name string
}

// Group representa um grupo de usuários.
type Group struct {
	Name string
}

// AWSManager é responsável por interagir com a AWS.
type AWSManager struct {
	Logger Logger
}

// CreateUser cria um novo usuário na AWS.
func (a *AWSManager) CreateUser(user User) error {
	cmd := exec.Command(awsCLICommand, "iam", "create-user", "--user-name", user.Name)
	err := cmd.Run()
	if err != nil {
		a.Logger.Log(fmt.Sprintf("Falha ao criar usuário %s: %v", user.Name, err))
		return err
	}
	a.Logger.Log(fmt.Sprintf("Usuário %s criado com sucesso.", user.Name))
	return nil
}

// AddUserToGroup adiciona um usuário a um grupo na AWS.
func (a *AWSManager) AddUserToGroup(user User, group Group) error {
	cmd := exec.Command(awsCLICommand, "iam", "add-user-to-group", "--user-name", user.Name, "--group-name", group.Name)
	err := cmd.Run()
	if err != nil {
		a.Logger.Log(fmt.Sprintf("Falha ao adicionar usuário %s ao grupo %s: %v", user.Name, group.Name, err))
		return err
	}
	a.Logger.Log(fmt.Sprintf("Usuário %s adicionado ao grupo %s com sucesso.", user.Name, group.Name))
	return nil
}

// CreateConsoleAccess cria acesso ao console AWS para um usuário.
func (a *AWSManager) CreateConsoleAccess(user User) error {
	a.Logger.Log(fmt.Sprintf("Adicionando acesso ao console AWS para o usuário %s...", user.Name))
	// Implemente a lógica para gerar uma senha aleatória de forma segura
	password := generateRandomPassword()

	cmd := exec.Command(awsCLICommand, "iam", "create-login-profile", "--user-name", user.Name, "--password-reset-required", "--password", password)
	err := cmd.Run()
	if err != nil {
		a.Logger.Log(fmt.Sprintf("Falha ao criar acesso ao console AWS para o usuário %s: %v", user.Name, err))
		return err
	}

	a.Logger.Log(fmt.Sprintf("Senha gerada para o usuário %s: %s", user.Name, password))
	// Implemente a lógica para salvar as informações de acesso do console em um arquivo ou exibi-las na tela
	return nil
}

// getTime retorna o tempo atual formatado.
func getTime() string {
	return time.Now().Format("2006-01-02 15:04:05")
}

// generateRandomPassword gera uma senha aleatória de forma segura.
func generateRandomPassword() string {
	// Implemente a lógica para gerar uma senha aleatória de forma segura aqui
	// Use uma biblioteca adequada para geração de senhas aleatórias
	return "senha_gerada_aleatoriamente"
}

func main() {
	logger := ConsoleLogger{}

	// Crie um scanner para ler a entrada do usuário
	scanner := bufio.NewScanner(os.Stdin)

	// Solicitar nome do usuário
	fmt.Print("Insira o nome do usuário a ser criado: ")
	scanner.Scan()
	username := scanner.Text()

	// Criar usuário
	user := User{Name: username}
	awsManager := AWSManager{Logger: logger}
	err := awsManager.CreateUser(user)
	if err != nil {
		os.Exit(1)
	}

	// Listar grupos existentes
	fmt.Println("Grupos existentes:")
	groups, err := listGroups()
	if err != nil {
		logger.Log(fmt.Sprintf("Erro ao listar grupos: %v", err))
		os.Exit(1)
	}

	for i, group := range groups {
		fmt.Printf("[%d]: %s\n", i, group.Name)
	}

	// Solicitar número do grupo
	fmt.Print("Escolha um número para o grupo do usuário: ")
	scanner.Scan()
	groupNumberStr := scanner.Text()
	groupNumber, err := strconv.Atoi(groupNumberStr)
	if err != nil || groupNumber < 0 || groupNumber >= len(groups) {
		logger.Log("Número de grupo inválido.")
		os.Exit(1)
	}
	group := groups[groupNumber]

	// Adicionar usuário ao grupo
	err = awsManager.AddUserToGroup(user, group)
	if err != nil {
		os.Exit(1)
	}

	// Criar acesso ao console AWS
	err = awsManager.CreateConsoleAccess(user)
	if err != nil {
		os.Exit(1)
	}
}

// listGroups lista os grupos existentes na AWS.
func listGroups() ([]Group, error) {
	cmd := exec.Command(awsCLICommand, "iam", "list-groups", "--query", "Groups[*].GroupName", "--output", "text")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	groupNames := strings.Fields(string(output))
	var groups []Group
	for _, name := range groupNames {
		group := Group{Name: name}
		groups = append(groups, group)
	}
	return groups, nil
}
