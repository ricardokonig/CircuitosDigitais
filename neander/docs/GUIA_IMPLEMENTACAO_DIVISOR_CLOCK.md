# Guia de Implementação: ID 5 - Divisor de Clock (50 MHz -> ~2 Hz)

Este documento descreve como implementar o módulo **Divisor de Clock** do processador Neander, atendendo à restrição **Estrutural** exigida na Tabela I do enunciado e aproveitando a arquitetura já desenvolvida no `LAB5`.

---

## 1. Requisitos e Especificação (PDF Neander)

Conforme a **Tabela I (ID 5)** e a Seção de Implementação em FPGA (Página 4):
* **Função:** Receber o clock de alta frequência da placa Altera DE0 (`50 MHz`, pino `PIN_G21`) e gerar um clock lento de **aproximadamente 2 Hz** (adequado para visualização humana dos passos e instruções nas placas e displays).
* **Restrição:** **Estrutural** (deve ser implementado através de células lógicas e flip-flops interligados, sem blocos comportamentais como `always @(posedge clk) contador <= contador + 1`).
* **Sinais:**
  * `clk_in`: Clock de 50 MHz da FPGA DE0.
  * `rst_n`: Reset assíncrono (ativo em 0).
  * `clk_out`: Clock dividido de ~2 Hz (enviado para o módulo `Run/Step Mode`).

---

## 2. Diagnóstico: O que já temos e por que é Parcial

* **No LAB8 (`ClockDiv.v`):**
  * O divisor foi implementado de forma **comportamental** com um registrador de 25 bits e um comparador:
    ```verilog
    always @(posedge clk_in) begin
        if (contador == 25'd24_999_999) begin
            contador <= 0;
            clk_out <= ~clk_out;
        end else begin
            contador <= contador + 1'b1;
        end
    end
    ```
  * Embora funcione na placa, **não atende à restrição "Estrutural"** estipulada para o ID 5.
* **No LAB5 (`lab5.zip`):**
  * O laboratório 5 continha exatamente a solução estrutural: o esquemático `LAB_5.bdf` continha 8 flip-flops D configurados com realimentação invertida ($D = \overline{Q}$), e o esquemático `top_divisor.bdf` colocava 3 blocos em série ($8 \times 3 = 24$ flip-flops em cascata).

---

## 3. Fundamentação Matemática da Divisão Estrutural

Cada flip-flop D com sua saída invertida ligada à entrada $D$ atua como um divisor de frequência por 2:
$$f_{\text{out}} = \frac{f_{\text{in}}}{2}$$

Ligando $N$ flip-flops em cascata (divisor assíncrono / *ripple counter*):
$$f_{\text{out}} = \frac{f_{\text{in}}}{2^N}$$

Para um clock de entrada $f_{\text{in}} = 50\text{ MHz} = 50\,000\,000\text{ Hz}$:
* Com $N = 24$ estágios:
  $$f_{\text{out}} = \frac{50\,000\,000}{2^{24}} = \frac{50\,000\,000}{16\,777\,216} \approx 2{,}98\text{ Hz} \approx 3\text{ Hz}$$
* Com $N = 25$ estágios:
  $$f_{\text{out}} = \frac{50\,000\,000}{2^{25}} = \frac{50\,000\,000}{33\,554\,432} \approx 1{,}49\text{ Hz} \approx 1{,}5\text{ Hz}$$

Ambos os valores atendem perfeitamente à especificação de **"aproximadamente 2 Hz"** da Tabela I, sem necessitar de nenhum somador ou comparador comportamental.

---

## 4. Código Verilog Estrutural Completo (`divisor_clock.v`)

O código abaixo implementa a cascata de 24 estágios de divisão estrutural em Verilog, utilizando a célula [ffd.v](file:///home/schons/Documentos/faculdade/3/ProjetoCD/trab/neander/src/ffd.v) já validada no projeto:

```verilog
`timescale 1ns/1ns

// ============================================================================
// Estagio individual divisor por 2 (Toggle Flip-Flop estrutural com ffd)
// ============================================================================
module div_stage (
    input  wire clk_in,
    input  wire rst_n,
    output wire clk_out
);
    wire not_q;

    // Realimenta a saida negada na entrada D
    not g_inv (not_q, clk_out);

    // Flip-flop D com reset assincrono ativo em 0
    ffd u_ff (
        .clk   (clk_in),
        .rst_n (rst_n),
        .d     (not_q),
        .q     (clk_out)
    );

endmodule

// ============================================================================
// Bloco de 8 estágios de divisão (Divisor por 256)
// ============================================================================
module div_8stages (
    input  wire clk_in,
    input  wire rst_n,
    output wire clk_out
);
    wire [7:0] q;

    div_stage s0 (.clk_in(clk_in), .rst_n(rst_n), .clk_out(q[0]));
    div_stage s1 (.clk_in(q[0]),   .rst_n(rst_n), .clk_out(q[1]));
    div_stage s2 (.clk_in(q[1]),   .rst_n(rst_n), .clk_out(q[2]));
    div_stage s3 (.clk_in(q[2]),   .rst_n(rst_n), .clk_out(q[3]));
    div_stage s4 (.clk_in(q[3]),   .rst_n(rst_n), .clk_out(q[4]));
    div_stage s5 (.clk_in(q[4]),   .rst_n(rst_n), .clk_out(q[5]));
    div_stage s6 (.clk_in(q[5]),   .rst_n(rst_n), .clk_out(q[6]));
    div_stage s7 (.clk_in(q[6]),   .rst_n(rst_n), .clk_out(q[7]));

    assign clk_out = q[7];

endmodule

// ============================================================================
// Top-Level do Divisor de Clock Estrutural (50 MHz -> ~3 Hz / 24 estágios)
// ============================================================================
module divisor_clock (
    input  wire clk_50MHz,    // Pino G21 da DE0
    input  wire rst_n,        // Reset assincrono (BUTTON0)
    output wire clk_2Hz       // Clock dividido (~2.98 Hz)
);
    wire clk_div8, clk_div16;

    // 1º bloco de 8 estagios: 50 MHz -> 195.3 kHz
    div_8stages b1 (
        .clk_in  (clk_50MHz),
        .rst_n   (rst_n),
        .clk_out (clk_div8)
    );

    // 2º bloco de 8 estagios: 195.3 kHz -> 762.9 Hz
    div_8stages b2 (
        .clk_in  (clk_div8),
        .rst_n   (rst_n),
        .clk_out (clk_div16)
    );

    // 3º bloco de 8 estagios: 762.9 Hz -> ~2.98 Hz
    div_8stages b3 (
        .clk_in  (clk_div16),
        .rst_n   (rst_n),
        .clk_out (clk_2Hz)
    );

endmodule
```

---

## 5. Como Integrar com o ID 6 (`Run/Step Mode`)

O sinal de saída `clk_2Hz` do divisor não vai diretamente para o processador: ele deve passar pelo módulo **ID 6 (Run/Step Mode)**, que comuta entre o clock contínuo e o botão de passo a passo:

```verilog
wire clk_lento;
wire clk_efetivo;

// 1. Divisor estrutural
divisor_clock u_divisor (
    .clk_50MHz (PIN_G21),
    .rst_n     (rst_n),
    .clk_2Hz   (clk_lento)
);

// 2. Run/Step Mode (SW0: 1 = RUN, 0 = DEBUG)
// Em RUN opera com clk_lento; em DEBUG opera com pulso de BUTTON1
assign clk_efetivo = (SW[0] == 1'b1) ? clk_lento : pulso_step_up;
```

---

## 6. Procedimento de Teste

Para validar a estrutura sem esperar milhões de ciclos no ModelSim / Icarus Verilog:
1. Simule apenas o módulo `div_8stages` injetando 512 pulsos de clock e observe a transição de saída a cada 256 pulsos.
2. Na síntese do Quartus, verifique no relatório do *Compilation Report* $\rightarrow$ *Fitter* que foram alocados exatamente **24 flip-flops**, comprovando que a estrutura foi sintetizada 100% como hardware dedicado.
