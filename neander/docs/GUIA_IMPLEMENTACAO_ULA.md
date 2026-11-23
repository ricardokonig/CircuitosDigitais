# Guia de Implementação: ID 4 - ULA Combinacional (Neander)

Este documento descreve detalhadamente o funcionamento e a implementação linha a linha da **Unidade Lógica e Aritmética (ULA)** do processador Neander, implementada de forma **combinacional comportamental** (RTL padrão da disciplina), conforme o arquivo [`src/ula.v`](../src/ula.v).

---

## 1. Requisitos e Especificação

Conforme a especificação do Neander e a documentação em [`docs/OPCODES.md`](OPCODES.md):

* **Função:** Executar as 5 operações da arquitetura Neander sobre palavras de 8 bits e computar combinacionalmente as flags de condição ($N$ e $Z$).
* **Restrição da Tabela I:** Livre (`-`), ou seja, **não exige implementação estrutural** com portas lógicas primitivas (diferente do decodificador de instruções, temporizador e PC). Pode ser descrita de forma comportamental limpa e direta.
* **Entradas:**
  * `x[7:0]`: Barramento de 8 bits com o dado do Acumulador (`AC`).
  * `y[7:0]`: Barramento de 8 bits com o dado lido da memória (`RDM`).
  * `selUAL[2:0]`: Seletor de 3 bits gerado pelo [`src/codificador_ula.v`](../src/codificador_ula.v).
* **Saídas:**
  * `s[7:0]`: Barramento de 8 bits com o resultado da operação selecionada.
  * `flag_n`: Flag Negativo (bit de sinal $S[7]$).
  * `flag_z`: Flag Zero ($1$ se todos os 8 bits de $S$ forem zero).

### Tabela de Operações da ULA (`selUAL[2:0]`)

| `selUAL[2:0]` | Operação | Código Verilog | Instrução Neander |
| :---: | :---: | :---: | :---: |
| `3'b000` | **Passa Y** | `s = y;` | `LDA` (carrega RDM no AC) |
| `3'b001` | **ADD** | `s = x + y;` | `ADD` (soma AC com RDM) |
| `3'b010` | **AND** | `s = x & y;` | `AND` (E lógico bit a bit) |
| `3'b011` | **OR** | `s = x \| y;` | `OR` (OU lógico bit a bit) |
| `3'b100` | **NOT** | `s = ~x;` | `NOT` (inversão bit a bit de AC) |
| Outros | Default | `s = 8'h00;` | Segurança / Códigos não utilizados |

---

## 2. Código Completo (`src/ula.v`)

```verilog
`timescale 1ns/1ns

// ULA combinacional comportamental do Neander (8 bits)
module ula (
    input  wire [7:0] x,       // Operando vindo do AC
    input  wire [7:0] y,       // Operando vindo do RDM / memoria
    input  wire [2:0] selUAL,  // Seletor de operacao (gerado pelo codificador_ula)
    output reg  [7:0] s,       // Resultado da ULA
    output wire       flag_n,  // Flag Negativo
    output wire       flag_z   // Flag Zero
);

    // 1. Logica combinacional das operacoes da ULA
    always @(*) begin
        case (selUAL)
            3'b000:  s = y;        // Passa Y (instrucao LDA)
            3'b001:  s = x + y;    // ADD
            3'b010:  s = x & y;    // AND
            3'b011:  s = x | y;    // OR
            3'b100:  s = ~x;       // NOT (inversao do AC)
            default: s = 8'h00;
        endcase
    end

    // 2. Geracao combinacional das flags de condicao
    assign flag_n = s[7];          // MSB indica sinal negativo em complemento a 2
    assign flag_z = (s == 8'h00);  // 1 se o resultado for identicamente zero (~|s)

endmodule
```

---

## 3. Explicação Linha a Linha do Código

### 3.1. Declaração do Módulo e Portas

```verilog
module ula (
    input  wire [7:0] x,       // Operando vindo do AC
    input  wire [7:0] y,       // Operando vindo do RDM / memoria
    input  wire [2:0] selUAL,  // Seletor de operacao (gerado pelo codificador_ula)
    output reg  [7:0] s,       // Resultado da ULA
    output wire       flag_n,  // Flag Negativo
    output wire       flag_z   // Flag Zero
);
```

* **`input wire [7:0] x, y`**: Os operandos de entrada. Em Verilog-2001, declarar explicitamente cada barramento evita ambiguidades de compilação.
* **`input wire [2:0] selUAL`**: O código de seleção de 3 bits, alinhado exatamente ao nome gerado pelo `codificador_ula.v` e `controle_top.v`.
* **`output reg [7:0] s`**: Declarado como `reg` porque seu valor é atribuído dentro de um bloco procedural combinacional `always @(*)`. Em síntese de hardware combinacional, isso é inferido como um multiplexador puro, **sem** criar nenhum registrador/flip-flop.
* **`output wire flag_n, flag_z`**: Declarados como `wire`, pois recebem atribuições contínuas (`assign`).

---

### 3.2. Bloco Combinacional das Operações (`always @(*)`)

```verilog
    always @(*) begin
        case (selUAL)
            3'b000:  s = y;        // Passa Y (instrucao LDA)
            3'b001:  s = x + y;    // ADD
            3'b010:  s = x & y;    // AND
            3'b011:  s = x | y;    // OR
            3'b100:  s = ~x;       // NOT (inversao do AC)
            default: s = 8'h00;
        endcase
    end
```

* **`always @(*)`**: O asterisco `(*)` instrui o sintetizador e o simulador a incluírem automaticamente todas as variáveis lidas no bloco (`x`, `y`, `selUAL`) na lista de sensibilidade. Isso garante que qualquer variação nas entradas recalcule a saída instantaneamente, sem risco de gerar latches indesejados.
* **`case (selUAL)`**: Multiplexador de controle direto:
  * **`3'b000: s = y;`**: Instrução `LDA`. Repassa os dados da memória intactos para o Acumulador.
  * **`3'b001: s = x + y;`**: Instrução `ADD`. Realiza a soma binária dos 8 bits de `x` com `y`.
  * **`3'b010: s = x & y;`**: Instrução `AND`. Realiza a operação lógica `E` bit a bit.
  * **`3'b011: s = x | y;`**: Instrução `OR`. Realiza a operação lógica `OU` bit a bit.
  * **`3'b100: s = ~x;`**: Instrução `NOT`. Inverte todos os 8 bits do operando `x` (Acumulador).
  * **`default: s = 8'h00;`**: Garante cobertura de todos os estados possíveis de 3 bits (`101`, `110`, `111`), prevenindo inferência de latches.

---

### 3.3. Geração Combinacional das Flags ($N$ e $Z$)

```verilog
    assign flag_n = s[7];          // MSB indica sinal negativo em complemento a 2
    assign flag_z = (s == 8'h00);  // 1 se o resultado for identicamente zero (~|s)
```

* **`assign flag_n = s[7];`**:
  * Em representação binária com sinal em **complemento a dois**, o bit mais significativo ($s[7]$) é o bit de sinal:
    * Se $s[7] = 0$, o número é positivo ou zero $\rightarrow N = 0$.
    * Se $s[7] = 1$, o número é negativo $\rightarrow N = 1$.
* **`assign flag_z = (s == 8'h00);`**:
  * A flag $Z$ vai para nível lógico alto (`1`) quando todos os bits do resultado forem zero.
  * É equivalente à redução NOR dos bits (`~|s`), acionando desvios na instrução `JZ`.

---

## 4. Integração no Datapath do Neander

A ULA conecta-se diretamente ao Acumulador (`AC`), ao Registrador de Dados da Memória (`RDM`) e ao Registrador de Flags (`reg_flags`):

```
                   +--------------+
AC [7:0] --------->| x            |
                   |              |---> s [7:0] ---> Entrada do AC
RDM [7:0] -------->| y     ULA    |
                   |              |---> flag_n ---> Entrada D do FF N
selUAL [2:0] ----->| selUAL       |---> flag_z ---> Entrada D do FF Z
                   +--------------+
```

As flags $N$ e $Z$ são armazenadas no registrador de flags somente quando o sinal de controle `cargaNZ` for ativado pela Unidade de Controle no ciclo de execução das instruções que alteram flags (`LDA`, `ADD`, `OR`, `AND`, `NOT`).

---

## 5. Simulação e Testes (`tb/tb_ula.v`)

O testbench em [`tb/tb_ula.v`](../tb/tb_ula.v) valida automaticamente todas as operações e combinações de flags:

```bash
# Executa apenas a ULA
make tb_ula

# Executa todos os testes do processador
make test
```

### Relatório de Verificações:
* **Passa Y:** Dados positivos (`0x55`), negativos (`0x80` $\rightarrow N=1$) e zero (`0x00` $\rightarrow Z=1$).
* **ADD:** Adição regular (`25 + 35 = 60`), adição com resultado negativo (`127 + 1 = 128` $\rightarrow N=1$) e overflow para zero (`255 + 1 = 0` $\rightarrow Z=1$).
* **AND:** Operação lógica com $N=1$ e com $Z=1$.
* **OR:** Operação lógica com dados positivos, negativos e zero.
* **NOT:** Inversão para negativo (`~0x0F = 0xF0` $\rightarrow N=1$) e inversão para zero (`~0xFF = 0x00` $\rightarrow Z=1$).

Total: **15 de 15 verificações aprovadas com 100% de sucesso**.
