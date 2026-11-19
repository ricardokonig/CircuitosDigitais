# Tabela de Opcodes e Sinais de Controle - Processador Neander

Este documento descreve detalhadamente todos os **16 códigos de operação (opcodes)** possíveis de 4 bits (`RI[7:4]`), divididos em instruções válidas e códigos sem instrução associada na arquitetura Neander.

---

## 1. Tabela Geral de Opcodes (Ordem Crescente)

Na arquitetura Neander, o campo de opcode ocupa os **4 bits mais significativos** do Registrador de Instrução (`RI[7:4]`). Os códigos válidos e os códigos sem instrução seguem a tabela abaixo:

| Opcode (Binário) | Opcode (Hex) | Mnemônico | Tipo de Operação | Total de Ciclos | Ciclos ($t_i$) | Descrição Funcional |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| `0000` | `0x0` | **NOP** | Controle | 4 | $t_0 \dots t_3$ | Nenhuma operação (*No Operation*). |
| `0001` | `0x1` | **STA** | Memória | 8 | $t_0 \dots t_7$ | Armazena o acumulador no endereço especificado: $\text{MEM}[\text{end}] \leftarrow \text{AC}$. |
| `0010` | `0x2` | **LDA** | Memória/ULA | 8 | $t_0 \dots t_7$ | Carrega o acumulador da memória: $\text{AC} \leftarrow \text{MEM}[\text{end}]$, atualiza N e Z. |
| `0011` | `0x3` | **ADD** | Aritmética | 8 | $t_0 \dots t_7$ | Soma dado da memória ao acumulador: $\text{AC} \leftarrow \text{AC} + \text{MEM}[\text{end}]$, atualiza N e Z. |
| `0100` | `0x4` | **OR** | Lógica | 8 | $t_0 \dots t_7$ | OU lógico bit a bit: $\text{AC} \leftarrow \text{AC} \lor \text{MEM}[\text{end}]$, atualiza N e Z. |
| `0101` | `0x5` | **AND** | Lógica | 8 | $t_0 \dots t_7$ | E lógico bit a bit: $\text{AC} \leftarrow \text{AC} \land \text{MEM}[\text{end}]$, atualiza N e Z. |
| `0110` | `0x6` | **NOT** | Lógica | 4 | $t_0 \dots t_3$ | Inverte os bits do acumulador: $\text{AC} \leftarrow \overline{\text{AC}}$, atualiza N e Z. |
| `0111` | `0x7` | *N/A* | *Sem instrução* | — | — | Código não mapeado no decodificador. Todas as saídas de instrução ficam em `0`. |
| `1000` | `0x8` | **JMP** | Desvio | 6 | $t_0 \dots t_5$ | Salto incondicional: $\text{PC} \leftarrow \text{end}$. |
| `1001` | `0x9` | **JN** | Desvio Cond. | 6 ou 4 | $t_0 \dots t_5$ / $t_0 \dots t_3$ | Salto se negativo ($N = 1$): $\text{PC} \leftarrow \text{end}$. Se $N = 0$, pula o operando e encerra em $t_3$. |
| `1010` | `0xA` | **JZ** | Desvio Cond. | 6 ou 4 | $t_0 \dots t_5$ / $t_0 \dots t_3$ | Salto se zero ($Z = 1$): $\text{PC} \leftarrow \text{end}$. Se $Z = 0$, pula o operando e encerra em $t_3$. |
| `1011` | `0xB` | *N/A* | *Sem instrução* | — | — | Código não mapeado no decodificador. |
| `1100` | `0xC` | *N/A* | *Sem instrução* | — | — | Código não mapeado no decodificador. |
| `1101` | `0xD` | *N/A* | *Sem instrução* | — | — | Código não mapeado no decodificador. |
| `1110` | `0xE` | *N/A* | *Sem instrução* | — | — | Código não mapeado no decodificador. |
| `1111` | `0xF` | **HLT** | Controle | — | $t_0 \dots t_2$ | Para a execução (*Halt*). Congela o temporizador no passo em que o opcode é decodificado. |

---

## 2. Ciclo de Busca Comum (Fetch)

Todas as instruções do Neander compartilham os passos de tempo $t_0$, $t_1$ e $t_2$, independentemente do opcode:

| Passo de Tempo | Sinais Ativos | Função no Neander |
| :---: | :---: | :--- |
| **$t_0$** | `cargaREM = 1` | Envia o endereço atual do PC para o Registrador de Endereço de Memória (`REM`). |
| **$t_1$** | `read = 1`, `incrementaPC = 1` | Lê o opcode da memória para o `RDM` e incrementa o `PC` para apontar para o próximo byte. |
| **$t_2$** | `cargaRI = 1` | Carrega o opcode do `RDM` no Registrador de Instrução (`RI`). |

---

## 3. Detalhamento dos Sinais de Controle por Instrução

### 3.1. `0000` (0x0) - NOP
- **$t_0 \dots t_2$**: Ciclo de busca padrão.
- **$t_3$**: `goto_t0 = 1`. Retorna ao passo $t_0$ no próximo pulso de clock. Total: **4 ciclos**.

### 3.2. `0001` (0x1) - STA
- **$t_3$**: `cargaREM = 1` (busca o byte de endereço do operando apontado pelo PC).
- **$t_4$**: `read = 1`, `incrementaPC = 1` (lê o operando da memória e incrementa PC).
- **$t_5$**: `cargaREM = 1`, `sel = 1` (seleciona o RDM como entrada do REM, apontando para o endereço do dado).
- **$t_6$**: `cargaRDM = 1` (prepara o dado do AC para o RDM).
- **$t_7$**: `write = 1`, `cargaAC = 1`, `cargaNZ = 1`, `goto_t0 = 1` (grava na memória e reinicia o ciclo). Total: **8 ciclos**.

### 3.3. `0010` (0x2) - LDA
- **$t_3$**: `cargaREM = 1`.
- **$t_4$**: `read = 1`, `incrementaPC = 1`.
- **$t_5$**: `cargaREM = 1`, `sel = 1`.
- **$t_6$**: `read = 1` (lê o dado da memória).
- **$t_7$**: `cargaAC = 1`, `cargaNZ = 1`, `ula_y = 1` (`selUAL = 000`), `goto_t0 = 1`. Total: **8 ciclos**.

### 3.4. `0011` (0x3) - ADD
- **$t_3 \dots t_6$**: Idêntico ao LDA (busca operando e busca dado).
- **$t_7$**: `cargaAC = 1`, `cargaNZ = 1`, `ula_add = 1` (`selUAL = 001`), `goto_t0 = 1`. Total: **8 ciclos**.

### 3.5. `0100` (0x4) - OR
- **$t_3 \dots t_6$**: Idêntico ao LDA.
- **$t_7$**: `cargaAC = 1`, `cargaNZ = 1`, `ula_or = 1` (`selUAL = 011`), `goto_t0 = 1`. Total: **8 ciclos**.

### 3.6. `0101` (0x5) - AND
- **$t_3 \dots t_6$**: Idêntico ao LDA.
- **$t_7$**: `cargaAC = 1`, `cargaNZ = 1`, `ula_and = 1` (`selUAL = 010`), `goto_t0 = 1`. Total: **8 ciclos**.

### 3.7. `0110` (0x6) - NOT
- **$t_0 \dots t_2$**: Ciclo de busca padrão.
- **$t_3$**: `cargaAC = 1`, `cargaNZ = 1`, `ula_not = 1` (`selUAL = 100`), `goto_t0 = 1`. Total: **4 ciclos**.

### 3.8. `0111` (0x7) - Sem Instrução
- Não gera ativação de nenhuma das 11 linhas do decodificador (`decod_inst.v`).

### 3.9. `1000` (0x8) - JMP
- **$t_3$**: `cargaREM = 1`.
- **$t_4$**: `read = 1`, `incrementaPC = 1`.
- **$t_5$**: `cargaPC = 1` (novo endereço carregado no PC), `goto_t0 = 1`. Total: **6 ciclos**.

### 3.10. `1001` (0x9) - JN
- **Se $N = 1$ (Salto Tomado)**:
  - **$t_3$**: `cargaREM = 1`.
  - **$t_4$**: `read = 1`, `incrementaPC = 1`.
  - **$t_5$**: `cargaPC = 1`, `goto_t0 = 1`. Total: **6 ciclos**.
- **Se $N = 0$ (Salto Não Tomado)**:
  - **$t_3$**: `incrementaPC = 1`, `goto_t0 = 1` (pula o endereço do operando e retorna imediatamente a $t_0$). Total: **4 ciclos**.

### 3.11. `1010` (0xA) - JZ
- **Se $Z = 1$ (Salto Tomado)**:
  - **$t_3$**: `cargaREM = 1`.
  - **$t_4$**: `read = 1`, `incrementaPC = 1`.
  - **$t_5$**: `cargaPC = 1`, `goto_t0 = 1`. Total: **6 ciclos**.
- **Se $Z = 0$ (Salto Não Tomado)**:
  - **$t_3$**: `incrementaPC = 1`, `goto_t0 = 1` (pula o operando e encerra em $t_3$). Total: **4 ciclos**.

### 3.12. `1011` a `1110` (0xB a 0xE) - Sem Instrução
- Códigos vagos da arquitetura. Todas as linhas de instrução decodificadas permanecem em `0`.

### 3.13. `1111` (0xF) - HLT
- **$t_0 \dots t_2$**: Busca e carregamento do opcode no RI.
- **$t_2 \dots \infty$**: A saída `hlt` do decodificador vai a `1`. O temporizador congela seu estado no flip-flop atual e não avança enquanto `hlt` permanecer ativo.

---

## 4. Tabela de Codificação da ULA (`selUAL`)

O codificador da ULA (`codificador_ula.v`) converte as saídas individuais da unidade de controle no barramento `selUAL[2:0]`:

| Comando da UC | `selUAL[2:0]` | Operação na ULA | Instrução Correspondente |
| :---: | :---: | :--- | :--- |
| `ula_y` | `3'b000` | Passa Y (dado vindo da memória) | **LDA** |
| `ula_add` | `3'b001` | Soma: $\text{AC} + \text{Y}$ | **ADD** |
| `ula_and` | `3'b010` | E lógico: $\text{AC} \land \text{Y}$ | **AND** |
| `ula_or` | `3'b011` | OU lógico: $\text{AC} \lor \text{Y}$ | **OR** |
| `ula_not` | `3'b100` | Inversão: $\overline{\text{AC}}$ | **NOT** |
| *Nenhum* | `3'b000` | Valor padrão quando inativo | Fetch / Saltos / NOP / STA |

---

## 5. Matriz de Sinais Ativos por Tempo ($t_0 \dots t_7$) e Operação

A tabela a seguir apresenta os sinais de controle ativados em cada passo de tempo ($t_0$ a $t_7$) para todas as operações implementadas na Unidade de Controle (`unidade_controle.v`):

| Instrução | $t_0$ | $t_1$ | $t_2$ | $t_3$ | $t_4$ | $t_5$ | $t_6$ | $t_7$ |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **NOP** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `goto_t0` | — | — | — | — |
| **STA** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `cargaREM` | `read`, `incrementaPC` | `sel`, `cargaREM` | `cargaRDM` | `write`, `cargaAC`, `cargaNZ`, `goto_t0` |
| **LDA** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `cargaREM` | `read`, `incrementaPC` | `sel`, `cargaREM` | `read` | `cargaAC`, `cargaNZ`, `ula_y`, `goto_t0` |
| **ADD** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `cargaREM` | `read`, `incrementaPC` | `sel`, `cargaREM` | `read` | `cargaAC`, `cargaNZ`, `ula_add`, `goto_t0` |
| **OR** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `cargaREM` | `read`, `incrementaPC` | `sel`, `cargaREM` | `read` | `cargaAC`, `cargaNZ`, `ula_or`, `goto_t0` |
| **AND** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `cargaREM` | `read`, `incrementaPC` | `sel`, `cargaREM` | `read` | `cargaAC`, `cargaNZ`, `ula_and`, `goto_t0` |
| **NOT** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `cargaAC`, `cargaNZ`, `ula_not`, `goto_t0` | — | — | — | — |
| **JMP** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `cargaREM` | `read`, `incrementaPC` | `cargaPC`, `goto_t0` | — | — |
| **JN ($N=1$)** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `cargaREM` | `read`, `incrementaPC` | `cargaPC`, `goto_t0` | — | — |
| **JN ($N=0$)** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `incrementaPC`, `goto_t0` | — | — | — | — |
| **JZ ($Z=1$)** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `cargaREM` | `read`, `incrementaPC` | `cargaPC`, `goto_t0` | — | — |
| **JZ ($Z=0$)** | `cargaREM` | `read`, `incrementaPC` | `cargaRI` | `incrementaPC`, `goto_t0` | — | — | — | — |
| **HLT** | `cargaREM` | `read`, `incrementaPC` | `cargaRI`, `hlt` *(congela)* | — | — | — | — | — |

---

## 6. Mapeamento dos Sinais de Controle e Respectivas Portas

| Sinal | Função | Condição Lógica de Ativação |
| :--- | :--- | :--- |
| `cargaREM` | Carrega o registrador de endereço de memória | $t_0 \lor (t_3 \land \text{inst\_end2}) \lor (t_5 \land \text{inst\_dado})$ |
| `sel` | Seleciona endereço do dado no MUX ($0 = \text{PC}, 1 = \text{RDM}$) | $t_5 \land \text{inst\_dado}$ |
| `read` | Habilita leitura da memória | $t_1 \lor (t_4 \land \text{inst\_end2}) \lor (t_6 \land \text{inst\_ula\_mem})$ |
| `write` | Habilita escrita na memória | $t_7 \land \text{sta}$ |
| `incrementaPC` | Avança o contador de programa | $t_1 \lor (t_4 \land \text{inst\_end2}) \lor (t_3 \land \text{jnnl\_jzzl})$ |
| `cargaPC` | Carrega novo endereço de salto no PC | $t_5 \land \text{jump\_valido}$ |
| `cargaRI` | Carrega o registrador de instrução com o opcode | $t_2$ |
| `cargaRDM` | Carrega dado do AC no RDM para escrita | $t_6 \land \text{sta}$ |
| `cargaAC` | Atualiza o acumulador com resultado | $(t_3 \land \text{not\_op}) \lor (t_7 \land \text{inst\_dado})$ |
| `cargaNZ` | Atualiza os flags de condição N e Z | `cargaAC` |
| `goto_t0` | Força reinicialização do temporizador para $t_0$ | $(t_3 \land (\text{nop} \lor \text{not\_op} \lor \text{jnnl\_jzzl})) \lor (t_5 \land \text{inst\_jump\_qualquer}) \lor (t_7 \land \text{inst\_dado})$ |
| `selUAL[2:0]` | Código de controle da ULA | Gerado a partir de `ula_y`, `ula_add`, `ula_and`, `ula_or`, `ula_not` |

