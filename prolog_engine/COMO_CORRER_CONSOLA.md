# Como correr o motor Prolog na consola

Guia rápido para abrir a consola do sistema pericial em SWI-Prolog, avaliar casos e mostrar as explicações.

## 1. Requisitos

- **SWI-Prolog 9 ou superior** (testado com a 10.0.2). Download: https://www.swi-prolog.org/download/stable
- No Windows, o instalador põe o executável em `C:\Program Files\swipl\bin\swipl.exe`. Se não marcaste a opção de o acrescentar ao PATH, usa o caminho completo (secção 2) ou acrescenta-o tu (secção 3).

Confirma a instalação:

```powershell
& "C:\Program Files\swipl\bin\swipl.exe" --version
```

## 2. Abrir a consola

Basta um terminal. Escolhe o que costumas usar.

### PowerShell (recomendado no Windows)

```powershell
cd "<pasta do projeto>\prolog_engine"
& "C:\Program Files\swipl\bin\swipl.exe" -s run_console.pl
```

- Substitui `<pasta do projeto>` pela pasta onde tens o repositório.
- Para escreveres só `swipl` nesta janela, acrescenta-o primeiro ao PATH (vale até fechares a janela):

  ```powershell
  $env:Path += ";C:\Program Files\swipl\bin"
  ```

### Git Bash

```bash
cd "<pasta do projeto>/prolog_engine"
"/c/Program Files/swipl/bin/swipl.exe" -s run_console.pl
```

### Com o `swipl` no PATH (macOS, Linux ou Windows configurado)

```bash
cd prolog_engine
swipl -s run_console.pl
```

Aparece o menu com os comandos disponíveis e a consola fica à espera, com o prompt `?-`.

> Se alterares o código ou fizeres `git pull`, sai com `halt.` e volta a abrir a consola. O `make.` recarrega os ficheiros, mas a base de conhecimento fica num módulo errado e aparecem avisos "Local definition of retail_rules:… overrides weak import".

## 3. Acrescentar o SWI-Prolog ao PATH (Windows, opcional)

1. Menu Iniciar → escreve **variáveis de ambiente** → **Editar as variáveis de ambiente do sistema**.
2. **Variáveis de Ambiente…** → em *Variáveis de utilizador*, seleciona **Path** → **Editar** → **Novo**.
3. Escreve `C:\Program Files\swipl\bin` e confirma com **OK**.
4. Fecha e volta a abrir o terminal. A partir daí basta `swipl`.

## 4. Comandos da consola

Cada comando termina com um **ponto final**, seguido de Enter.

| Comando | O que faz |
|---|---|
| `ajuda.` | Mostra a lista de comandos. |
| `listar_cenarios.` | Lista os 10 cenários de teste pré-definidos. |
| `cenario(N).` | Executa o cenário `N` (1 a 10) e mostra a decisão, as regras disparadas e as justificações. |
| `avaliar_interativo.` | Triagem guiada: o motor faz as perguntas à medida que as regras precisam delas. |
| `como(decisao(rever)).` | **Como?** Mostra a cadeia de factos e regras que levou a uma conclusão. Também aceita o número de um facto: `como(25).` |
| `whynot(decisao(permitir)).` | **Porque não?** Mostra porque é que uma conclusão não foi tirada. |
| `output_why.` | **Porquê da decisão.** Lista os motivos de todas as regras que dispararam. |
| `what_if([revendivel(true)], [], R).` | **E se?** Simula o caso com factos alterados e mostra se a decisão muda, sem alterar a sessão. |
| `factos.` | Lista todos os factos da memória de trabalho. |
| `limpar.` | Limpa a sessão para começar outro caso. |
| `halt.` | Sai do Prolog. |

### Durante a triagem interativa

- Responde com um dos valores sugeridos entre parênteses (por exemplo `sim`, `nao`, `mainline`).
- `porquê?` mostra a regra que está a pedir esse dado, o objetivo que está a tentar provar e o fundamento.
- `nao_sei` (ou `?`) regista que não sabes. O motor não cria nenhum facto e segue por outras regras.
- Às perguntas sobre dias responde com um número inteiro (0 ou mais). Outra resposta, como `abc` ou `-3`, mostra um aviso e a pergunta repete-se.
- Cada pergunta é feita uma só vez. Se a resposta não servir à regra que a pediu, essa regra não dispara e o motor segue para as seguintes.

## 5. Exemplo de demonstração

```prolog
?- cenario(1).                           % etiquetas soltas → rever (PC-002)
?- como(decisao(rever)).                 % Como?
?- output_why.                           % Porquê da decisão
?- what_if([revendivel(true)], [], R).   % E se? → rever passa a permitir
?- cenario(4).                           % peça com bainha → recusar (paragem HS-003)
?- whynot(decisao(permitir)).            % Porque não? → mostra a paragem HS-003
?- avaliar_interativo.                   % responde "porquê?" à pergunta dos dias
```

Notas:

- No cenário 1, `whynot(decisao(permitir))` gera uma árvore muito longa. Para mostrar o "Porque não?", usa o cenário 4.
- As 5 primeiras perguntas da triagem (colaborador, SKU, categoria, estado da peça e comprovativo) são os dados de partida, pedidos antes de o motor arrancar. Nelas, `porquê?` dá uma explicação genérica, porque ainda não há nenhuma regra a pedi-las. Para mostrar o "porquê?" com regra, usa a pergunta dos dias.

## 6. Correr os testes

Fora da consola, na pasta `prolog_engine`:

```bash
swipl run_tests.pl
```

Corre todas as suites PLUnit e termina com o código de saída 0 se passarem todas. No Windows sem PATH, usa o caminho completo do `swipl.exe`, como na secção 2.

Dentro da consola, o comando `testar.` corre as mesmas 8 suites (150 testes) e diz no fim se passaram todos ou se houve falhas.