# Guia de Implementação: ID 8 - PC (Program Counter)

Este documento descreve detalhadamente como implementar o módulo **PC (Program Counter)** do processador Neander, atendendo à restrição **Estrutural** e integrando-se diretamente aos sinais da Unidade de Controle (`controle_top.v`).

---

## 1. Requisitos e Especificação (PDF Neander)

Conforme a **Tabela I (ID 8)** e a arquitetura Neander:
* **Função:** Registrador contador de 8 bits responsável por armazenar o endereço da próxima instrução ou do próximo operando na memória.
* **Restrição:** **Estrutural** (deve ser construído com células lógicas, fatias de bit e flip-flops, sem construções RTL comportamentais como `always @(posedge clk) PC <= PC + 1`).
* **Sinais de Controle:**
  * `clk`: Clock do sistema (vem do módulo `Run/Step Mode`).
  * `rst_n`: Reset assíncrono geral (ativo em 0, via `BUTTON0` da DE0). Zera o PC para `8'h00`.
  * `cargaPC`: Sinal síncrono vindo da Unidade de Controle. Quando ativo (`1`), carrega no PC o endereço de salto presente no barramento de dados (`RDM[7:0]`). Ocorre no passo $t_5$ das instruções `JMP`, `JN` (se $N=1$) e `JZ` (se $Z=1$).
  * `incrementaPC`: Sinal síncrono vindo da Unidade de Controle. Quando ativo (`1`), soma 1 ao valor atual do PC ($PC \leftarrow PC + 1$). Ocorre nos passos de busca ($t_1$ e $t_4$) e no passo $t_3$ de desvios não tomados.
* **Entrada de Dados:** `D[7:0]` (8 bits vindos do barramento interno / saída do `RDM`).
* **Saída:** `Q[7:0]` (8 bits conectados ao MUX do `REM` e aos displays `HEX3` e `HEX2`).

---

## 2. Diagnóstico: O que já temos e por que é Parcial

No arquivo `CircuitosDigitais/LAB8.zip`, já existe o arquivo `contador_8b.v`:
* **Ponto positivo:** Ele já foi projetado de forma estrutural com `bit_slice`, encadeando 8 fatias com propagação de carry (`Cin` / `Cout`).
* **Por que é parcial?**
  1. O módulo `d_ff` utilizado no LAB8 **não possui pino de reset assíncrono** (`always @(posedge clk) q <= d;`). No Neander, o PC precisa ser zerado no reset assíncrono do sistema.
  2. A interface de controle do LAB8 usava um seletor genérico de 2 bits `Sel[1:0]` (com operações de carga, hold, incremento e decremento). O Neander não possui decremento e utiliza os sinais nominais `cargaPC` e `incrementaPC`.
  3. Agora já temos no projeto a célula estrutural oficial `ffd.v` (com entrada `rst_n`).

---

## 3. Arquitetura Estrutural Proposta

O contador deve ser estruturado em **8 fatias de 1 bit (`pc_slice`)** conectadas em cascata (Ripple Carry).

### 3.1. Lógica de Cada Bit ($i = 0 \dots 7$)
Para cada bit $i$:
1. **Meio-Somador (Half-Adder):**
   * $\text{soma}_i = Q_i \oplus C_{\text{in}, i}$
   * $C_{\text{out}, i} = Q_i \land C_{\text{in}, i}$
   * Para o bit 0, o carry de entrada é ativado diretamente pelo sinal de controle: $C_{\text{in}, 0} = \text{incrementaPC}$.
2. **Multiplexador de Próximo Estado:**
   * Se $\text{cargaPC} = 1$: próximo bit $= D_i$ (Carga paralela do salto).
   * Senão se $\text{incrementaPC} = 1$: próximo bit $= \text{soma}_i$ (Incremento).
   * Senão: próximo bit $= Q_i$ (Mantém o valor atual).
3. **Armazenamento:**
   * Instância de `ffd` com `clk` e `rst_n`.

```
                    D[i] ----------+
                                   |
                                   v
             +---------+      +----------+      +-------+
Cin[i] ----->| Half    |----->| MUX      |----->|  FFD  |-----> Q[i]
             | Adder   | soma | 4:1 ou   |  d   |       |   |
Q[i]   ---+->|         |      | Lógica   |      +-------+   |
          |  +---------+      +----------+          ^       |
          |       |                 ^               |       |
          |       v                 |               | clk   |
          |    Cout[i]        cargaPC, incPC        | rst_n |
          +-----------------------------------------+-------+
```

---

## 4. Código Verilog Estrutural Completo (`pc.v`)

Crie o arquivo `pc.v` no diretório base com o seguinte conteúdo:

```verilog
`timescale 1ns/1ns

// ============================================================================
// Fatia de 1 bit do Program Counter (PC Slice)
// ============================================================================
module pc_slice (
    input  wire clk,
    input  wire rst_n,
    input  wire D,              // Dado de entrada para carga
    input  wire cargaPC,        // Sinal de carga paralela
    input  wire incrementaPC,   // Sinal de incremento
    input  wire Cin,            // Carry-in do incremento
    output wire Cout,           // Carry-out para a proxima fatia
    output wire Q               // Estado atual do bit
);
    wire w_q;
    assign Q = w_q;

    // Meio-somador para o incremento
    wire soma;
    xor g_xor_soma (soma, w_q, Cin);
    and g_and_cout (Cout, w_q, Cin);

    // MUX de selecao do proximo estado:
    // Prioridade: cargaPC > incrementaPC > manter
    // d = (cargaPC & D) | (~cargaPC & incrementaPC & soma) | (~cargaPC & ~incrementaPC & w_q)
    wire n_carga, n_inc;
    not g_ncarga (n_carga, cargaPC);
    not g_ninc   (n_inc, incrementaPC);

    wire termo_carga, termo_inc, termo_hold, d_in;
    and g_tcarga (termo_carga, cargaPC, D);
    and g_tinc   (termo_inc, n_carga, incrementaPC, soma);
    and g_thold  (termo_hold, n_carga, n_inc, w_q);
    or  g_or_d   (d_in, termo_carga, termo_inc, termo_hold);

    // Flip-flop D com reset assincrono ativo em 0
    ffd u_ffd (
        .clk   (clk),
        .rst_n (rst_n),
        .d     (d_in),
        .q     (w_q)
    );

endmodule

// ============================================================================
// Top-Level do Program Counter de 8 bits (PC)
// ============================================================================
module pc (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       cargaPC,
    input  wire       incrementaPC,
    input  wire [7:0] D,        // Barramento vindo do RDM para saltos
    output wire [7:0] Q         // Endereco de saida para o REM e Displays
);
    wire [7:0] c;

    // Bit 0: Cin eh ativado pelo sinal incrementaPC
    pc_slice bit0 (.clk(clk), .rst_n(rst_n), .D(D[0]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(incrementaPC), .Cout(c[0]), .Q(Q[0]));
    pc_slice bit1 (.clk(clk), .rst_n(rst_n), .D(D[1]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[0]),          .Cout(c[1]), .Q(Q[1]));
    pc_slice bit2 (.clk(clk), .rst_n(rst_n), .D(D[2]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[1]),          .Cout(c[2]), .Q(Q[2]));
    pc_slice bit3 (.clk(clk), .rst_n(rst_n), .D(D[3]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[2]),          .Cout(c[3]), .Q(Q[3]));
    pc_slice bit4 (.clk(clk), .rst_n(rst_n), .D(D[4]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[3]),          .Cout(c[4]), .Q(Q[4]));
    pc_slice bit5 (.clk(clk), .rst_n(rst_n), .D(D[5]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[4]),          .Cout(c[5]), .Q(Q[5]));
    pc_slice bit6 (.clk(clk), .rst_n(rst_n), .D(D[6]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[5]),          .Cout(c[6]), .Q(Q[6]));
    pc_slice bit7 (.clk(clk), .rst_n(rst_n), .D(D[7]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[6]),          .Cout(c[7]), .Q(Q[7]));

endmodule
```

---

## 5. Integração com o Neander Top-Level

No módulo principal do Neander, o `pc` deve ser instanciado da seguinte forma:

```verilog
wire [7:0] pc_out;

pc u_pc (
    .clk          (clk_efetivo),   // Saida do Run/Step Mode
    .rst_n        (rst_n),         // BUTTON0
    .cargaPC      (cargaPC),       // Saida de controle_top
    .incrementaPC (incrementaPC),  // Saida de controle_top
    .D            (rdm_out),       // Barramento vindo do RDM
    .Q            (pc_out)         // Vai para o MUX do REM e HEX3..HEX2
);
```

---

## 6. Procedimento de Teste Unitário

Para validar com o Icarus Verilog (`iverilog`):
1. Crie um testbench simples aplicando pulso em `rst_n` e verificando se `Q == 8'h00`.
2. Habilite `incrementaPC = 1` por 5 ciclos de clock e verifique se o PC conta: `0x00 -> 0x01 -> 0x02 -> 0x03 -> 0x04 -> 0x05`.
3. Aplique `D = 8'h80` e `cargaPC = 1` em um ciclo, verificando se no próximo flanco o PC assume `0x80`.
4. Mantenha `cargaPC = 0` e `incrementaPC = 0` e verifique se o valor `0x80` se mantém inalterado.
