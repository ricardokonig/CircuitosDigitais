# Guia de Implementação: ID 12 - Decodificador BCD / Hex para 7 Segmentos

Este documento descreve como implementar o módulo **Decodificador Hexadecimal para 7 Segmentos (`bcd_7seg`)**, atendendo rigorosamente à restrição **Estrutural** exigida na Tabela I do projeto Neander e preparando-o para acionar os 4 displays da placa Altera DE0 (`EP3C16F484C6`).

---

## 1. Requisitos e Especificação (PDF Neander)

Conforme a **Tabela I (ID 12)** e a Seção de Implementação em FPGA (Página 4):
* **Função:** Converter valores de 4 bits (hexadecimal de `0` a `F`) para o formato de 7 segmentos (`a` a `g`).
* **Restrição:** **Estrutural** (deve ser implementado através de portas lógicas ou mintermos decodificados, sem blocos comportamentais como `case` ou `if`).
* **Mapeamento nos Displays da DE0:**
  * O processador Neander necessita de **4 displays**:
    * **HEX3 e HEX2:** Exibem o valor do `PC` (8 bits: `PC[7:4]` no HEX3 e `PC[3:0]` no HEX2).
    * **HEX1 e HEX0:** Exibem o valor do `AC` (8 bits: `AC[7:4]` no HEX1 e `AC[3:0]` no HEX0).
* **Padrão dos Displays da DE0:**
  * Lógica **ativa em nível baixo (Active-Low)**:
    * `0`: Segmento **aceso**.
    * `1`: Segmento **apagado**.
  * Ordem dos segmentos na saída `seg[6:0]`:
    * `seg[0]`: segmento `a`
    * `seg[1]`: segmento `b`
    * `seg[2]`: segmento `c`
    * `seg[3]`: segmento `d`
    * `seg[4]`: segmento `e`
    * `seg[5]`: segmento `f`
    * `seg[6]`: segmento `g`

---

## 2. Diagnóstico: O que já temos e por que é Parcial

No arquivo `CircuitosDigitais/LAB8.zip`, já existe o arquivo `BCD_7seg.v`:
* **Ponto positivo:** A tabela de mapeamento visual para a DE0 está correta e testada.
* **Por que é parcial?**
  * Ele foi escrito de forma **comportamental** com uma cláusula `always @(bcd_in)` e uma instrução `case(bcd_in)`:
    ```verilog
    always @(bcd_in) begin
        case(bcd_in)
            4'h0: seg_out = 7'b1000000;
            ...
    ```
  * A Tabela I do PDF impõe expressamente: **Restrição: Estrut.** (Estrutural). Para cumprir 100% dos critérios de avaliação, a conversão deve ser estrutural (portas lógicas combinacionais).

---

## 3. Arquitetura Estrutural Proposta (Decodificador 4:16 + Matriz OR)

A forma canônica, robusta e modular de implementar um decodificador de 7 segmentos estrutural consiste em:
1. Um **decodificador 4 para 16 estrutural** (usando 4 inversores e 16 portas `and` de 4 entradas), gerando os mintermos $m_0 \dots m_{15}$. *(Mesma técnica usada no `decod_inst.v`)*.
2. Portas `or` estruturais para cada segmento que deve ficar **apagado (`1`)** conforme os mintermos correspondentes.

### Tabela Verdade (Active-Low: 1 = Apagado)

| Dígito | Hex | Segmentos Apagados (`1`) | Mintermos para Nível 1 |
| :---: | :---: | :--- | :--- |
| **0** | `0x0` | `g` | $m_0$ |
| **1** | `0x1` | `a, d, e, f, g` | $m_1$ |
| **2** | `0x2` | `c, f` | $m_2$ |
| **3** | `0x3` | `e, f` | $m_3$ |
| **4** | `0x4` | `a, d, e` | $m_4$ |
| **5** | `0x5` | `b, e` | $m_5$ |
| **6** | `0x6` | `b` | $m_6$ |
| **7** | `0x7` | `d, e, f, g` | $m_7$ |
| **8** | `0x8` | *(nenhum, todos acesos)* | — |
| **9** | `0x9` | `e` | $m_9$ |
| **A** | `0xA` | `d` | $m_{10}$ |
| **B** | `0xB` | `a, b` | $m_{11}$ |
| **C** | `0xC` | `b, c, g` | $m_{12}$ |
| **D** | `0xD` | `a, f` | $m_{13}$ |
| **E** | `0xE` | `b, c` | $m_{14}$ |
| **F** | `0xF` | `b, c, d` | $m_{15}$ |

### Expressões Booleanas dos Segmentos (Nível Alto = Apagado)
* **$seg[0]$ (a):** $m_1 + m_4 + m_{11} + m_{13}$
* **$seg[1]$ (b):** $m_5 + m_6 + m_{11} + m_{12} + m_{14} + m_{15}$
* **$seg[2]$ (c):** $m_2 + m_{12} + m_{14} + m_{15}$
* **$seg[3]$ (d):** $m_1 + m_4 + m_7 + m_{10} + m_{15}$
* **$seg[4]$ (e):** $m_1 + m_3 + m_4 + m_5 + m_7 + m_9$
* **$seg[5]$ (f):** $m_1 + m_2 + m_3 + m_7 + m_{13}$
* **$seg[6]$ (g):** $m_0 + m_1 + m_7 + m_{12}$

---

## 4. Código Verilog Estrutural Completo (`bcd_7seg.v`)

Crie o arquivo `bcd_7seg.v` no diretório base com o seguinte código:

```verilog
`timescale 1ns/1ns

module bcd_7seg (
    input  wire [3:0] in,      // Valor hexadecimal de 4 bits (0 a F)
    output wire [6:0] seg      // Saidas ativas em 0: seg[0]=a ... seg[6]=g
);
    // 1. Inversores dos bits de entrada
    wire n3, n2, n1, n0;
    not g_n3 (n3, in[3]);
    not g_n2 (n2, in[2]);
    not g_n1 (n1, in[1]);
    not g_n0 (n0, in[0]);

    // 2. Geracao dos 16 mintermos com portas AND de 4 entradas
    wire m0, m1, m2, m3, m4, m5, m6, m7;
    wire m8, m9, m10, m11, m12, m13, m14, m15;

    and g_m0  (m0,  n3,    n2,    n1,    n0);    // 0x0
    and g_m1  (m1,  n3,    n2,    n1,    in[0]); // 0x1
    and g_m2  (m2,  n3,    n2,    in[1], n0);    // 0x2
    and g_m3  (m3,  n3,    n2,    in[1], in[0]); // 0x3
    and g_m4  (m4,  n3,    in[2], n1,    n0);    // 0x4
    and g_m5  (m5,  n3,    in[2], n1,    in[0]); // 0x5
    and g_m6  (m6,  n3,    in[2], in[1], n0);    // 0x6
    and g_m7  (m7,  n3,    in[2], in[1], in[0]); // 0x7
    and g_m8  (m8,  in[3], n2,    n1,    n0);    // 0x8
    and g_m9  (m9,  in[3], n2,    n1,    in[0]); // 0x9
    and g_m10 (m10, in[3], n2,    in[1], n0);    // 0xA
    and g_m11 (m11, in[3], n2,    in[1], in[0]); // 0xB
    and g_m12 (m12, in[3], in[2], n1,    n0);    // 0xC
    and g_m13 (m13, in[3], in[2], n1,    in[0]); // 0xD
    and g_m14 (m14, in[3], in[2], in[1], n0);    // 0xE
    and g_m15 (m15, in[3], in[2], in[1], in[0]); // 0xF

    // 3. Matriz OR para cada segmento (nivel 1 apaga o segmento)
    or g_sega (seg[0], m1, m4, m11, m13);
    or g_segb (seg[1], m5, m6, m11, m12, m14, m15);
    or g_segc (seg[2], m2, m12, m14, m15);
    or g_segd (seg[3], m1, m4, m7, m10, m15);
    or g_sege (seg[4], m1, m3, m4, m5, m7, m9);
    or g_segf (seg[5], m1, m2, m3, m7, m13);
    or g_segg (seg[6], m0, m1, m7, m12);

endmodule
```

---

## 5. Instanciação dos 4 Displays no Top-Level Neander

No módulo principal (`neander_top.v`), você instanciará o decodificador 4 vezes:

```verilog
// --- Displays para o Program Counter (PC) ---
bcd_7seg disp_pc_alto  (.in(pc_out[7:4]), .seg(hex3)); // HEX3: digito mais significativo do PC
bcd_7seg disp_pc_baixo (.in(pc_out[3:0]), .seg(hex2)); // HEX2: digito menos significativo do PC

// --- Displays para o Acumulador (AC) ---
bcd_7seg disp_ac_alto  (.in(ac_out[7:4]), .seg(hex1)); // HEX1: digito mais significativo do AC
bcd_7seg disp_ac_baixo (.in(ac_out[3:0]), .seg(hex0)); // HEX0: digito menos significativo do AC
```

---

## 6. Mapeamento dos Pinos no Arquivo `.qsf` (Placa Altera DE0)

Adicione as seguintes atribuições no seu arquivo `.qsf`:

```tcl
# HEX0 (AC baixo)
set_location_assignment PIN_E11 -to hex0[0]
set_location_assignment PIN_F11 -to hex0[1]
set_location_assignment PIN_H12 -to hex0[2]
set_location_assignment PIN_H13 -to hex0[3]
set_location_assignment PIN_G12 -to hex0[4]
set_location_assignment PIN_F12 -to hex0[5]
set_location_assignment PIN_F13 -to hex0[6]

# HEX1 (AC alto)
set_location_assignment PIN_A13 -to hex1[0]
set_location_assignment PIN_B13 -to hex1[1]
set_location_assignment PIN_C13 -to hex1[2]
set_location_assignment PIN_A14 -to hex1[3]
set_location_assignment PIN_B14 -to hex1[4]
set_location_assignment PIN_E14 -to hex1[5]
set_location_assignment PIN_A15 -to hex1[6]

# HEX2 (PC baixo)
set_location_assignment PIN_D15 -to hex2[0]
set_location_assignment PIN_A16 -to hex2[1]
set_location_assignment PIN_B16 -to hex2[2]
set_location_assignment PIN_E15 -to hex2[3]
set_location_assignment PIN_A17 -to hex2[4]
set_location_assignment PIN_B17 -to hex2[5]
set_location_assignment PIN_F14 -to hex2[6]

# HEX3 (PC alto)
set_location_assignment PIN_B18 -to hex3[0]
set_location_assignment PIN_F15 -to hex3[1]
set_location_assignment PIN_A19 -to hex3[2]
set_location_assignment PIN_B19 -to hex3[3]
set_location_assignment PIN_C19 -to hex3[4]
set_location_assignment PIN_D19 -to hex3[5]
set_location_assignment PIN_G15 -to hex3[6]
```
