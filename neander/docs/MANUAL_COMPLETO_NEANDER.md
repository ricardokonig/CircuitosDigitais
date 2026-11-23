# Manual Completo de Arquitetura e Implementação: Processador Neander

Este documento é a documentação técnica definitiva do processador **Neander de 8 bits com Memória**, desenvolvido para a disciplina de Circuitos Digitais (INF01086 - UFRGS). Ele descreve a arquitetura do sistema, o funcionamento de cada módulo, as equações lógicas, os códigos-fonte Verilog completos e o procedimento de validação e síntese em FPGA (Altera Cyclone III `EP3C16F484C6` - Placa DE0).

---

## 1. Visão Geral da Arquitetura do Neander

O Neander é um processador didático clássico baseado em arquitetura de acumulador de 8 bits com espaço de endereçamento linear de 256 bytes ($2^8 = 256$).

```mermaid
flowchart TD
    subgraph CLK_GEN ["Subsistema de Clock (IDs 5 e 6)"]
        CLK50["clk_50MHz (PIN_G21)"] --> DIV["divisor_clock (24 FFDs)"]
        DIV -->|clk_2Hz| RSM["run_step_mode"]
        SW0["SW0 (modo_run)"] --> RSM
        BTN1["BUTTON1 (btn_step_n)"] --> RSM
        RSM -->|clk_cpu| CLK_NET["Clock da CPU"]
    end

    subgraph CONTROL ["Unidade de Controle e Temporizacao"]
        CLK_NET --> TEMP["temporizador (t0..t7)"]
        RI_OP["RI[7:4] (Opcode)"] --> DEC["decod_inst"]
        DEC --> UC["unidade_controle (Combinacional)"]
        TEMP --> UC
        FLAGS_REG["reg_flags (N, Z)"] -->|flag_n, flag_z| UC
        UC --> COD_ULA["codificador_ula"]
        COD_ULA -->|selUAL[2:0]| ULA_BLK["ula"]
        UC -->|Sinais de Controle| DP["Datapath"]
    end

    subgraph DATAPATH ["Datapath de 8 bits"]
        PC["pc (Program Counter)"] -->|pc_out| MUX_REM["mux2x1_8b (MUX REM)"]
        RDM["reg_rdm (RDM)"] -->|rdm_out| MUX_REM
        RDM -->|Salto| PC
        RDM -->|Opcode| RI["reg_ri (RI)"]
        MUX_REM -->|rem_in| REM["reg_rem (REM)"]
        REM -->|rem_out (addr)| MEM["memoria (256x8)"]
        MEM -->|data_out| MUX_RDM["mux2x1_8b (MUX RDM)"]
        AC["reg_ac (Acumulador)"] -->|ac_out| MUX_RDM
        MUX_RDM -->|rdm_in| RDM
        AC -->|x| ULA_BLK
        RDM -->|y| ULA_BLK
        ULA_BLK -->|s| AC
        ULA_BLK -->|flags| FLAGS_REG
        RDM -->|data_in| MEM
    end

    subgraph PERIPHERALS ["Periféricos e Interface FPGA DE0"]
        PC -->|PC[7:0]| DISP_PC["Displays HEX3 e HEX2"]
        AC -->|AC[7:0]| DISP_AC["Displays HEX1 e HEX0"]
        FLAGS_REG -->|flag_n| LED0["LEDG0 (N)"]
        FLAGS_REG -->|flag_z| LED1["LEDG1 (Z)"]
        RI -->|Opcode F| LED5["LEDG5 (HLT)"]
    end
```

---

## 2. Subsistema de Controle e Temporização

### 2.1. Flip-Flop D Estrutural (`src/ffd.v`)
* **Função:** Elemento biestável de 1 bit com reset assíncrono ativo em nível baixo (`rst_n`), utilizado como bloco construtor dos registradores e do temporizador.
* **Código:**
```verilog
`timescale 1ns/1ns

module ffd (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule
```

---

### 2.2. Temporizador em Anel (`src/temporizador.v`) – ID 10
* **Função:** Gera uma sequência cíclica de 8 passos de tempo em código *one-hot* ($t_0$ a $t_7$).
* **Entradas de Controle:**
  - `goto_t0`: Força o anel a retornar a $t_0$ no próximo ciclo de clock.
  - `hlt`: Desabilita a realimentação e congela a contagem no passo atual.
* **Equações do Próximo Estado:**
  - $D_0 = \text{rst\_n} \land ((\sim \text{hlt} \land \text{goto\_t0}) \lor (\sim \text{hlt} \land \sim \text{goto\_t0} \land t_7) \lor (\text{hlt} \land t_0))$
  - $D_i = \sim \text{hlt} \land \sim \text{goto\_t0} \land t_{i-1} \lor (\text{hlt} \land t_i) \quad (i = 1 \dots 7)$
* **Código:**
```verilog
`timescale 1ns/1ns

module temporizador (
    input  wire clk,
    input  wire rst_n,
    input  wire goto_t0,
    input  wire hlt,
    output wire t0, t1, t2, t3, t4, t5, t6, t7
);
    wire not_hlt, not_goto_t0;
    not g_nhlt (not_hlt, hlt);
    not g_ngt0 (not_goto_t0, goto_t0);

    wire d0, d1, d2, d3, d4, d5, d6, d7;
    wire t0_reg, t1_reg, t2_reg, t3_reg, t4_reg, t5_reg, t6_reg, t7_reg;

    assign t0 = t0_reg; assign t1 = t1_reg; assign t2 = t2_reg; assign t3 = t3_reg;
    assign t4 = t4_reg; assign t5 = t5_reg; assign t6 = t6_reg; assign t7 = t7_reg;

    // Proximo bit 0: ativo no reset, ao fim de instrucao (goto_t0), no rollover de t7 ou sob HLT em t0
    wire termo_goto, termo_t7, termo_t0_hlt;
    and g_a_gt0   (termo_goto,   not_hlt, goto_t0);
    and g_a_t7    (termo_t7,     not_hlt, not_goto_t0, t7_reg);
    and g_a_t0hlt (termo_t0_hlt, hlt,     t0_reg);
    or  g_or_d0   (d0, termo_goto, termo_t7, termo_t0_hlt);

    // Flip-flop para t0: inicializa em 1
    wire q_n0;
    ffd ff0 (.clk(clk), .rst_n(rst_n), .d(~d0), .q(q_n0));
    not g_inv0 (t0_reg, q_n0);

    // Passos t1 a t7: propagacao em anel
    wire avanca_t1, hold_t1;
    and g_av1 (avanca_t1, not_hlt, not_goto_t0, t0_reg);
    and g_hd1 (hold_t1,   hlt,     t1_reg);
    or  g_or1 (d1,        avanca_t1, hold_t1);
    ffd ff1 (.clk(clk), .rst_n(rst_n), .d(d1), .q(t1_reg));

    wire avanca_t2, hold_t2;
    and g_av2 (avanca_t2, not_hlt, not_goto_t0, t1_reg);
    and g_hd2 (hold_t2,   hlt,     t2_reg);
    or  g_or2 (d2,        avanca_t2, hold_t2);
    ffd ff2 (.clk(clk), .rst_n(rst_n), .d(d2), .q(t2_reg));

    wire avanca_t3, hold_t3;
    and g_av3 (avanca_t3, not_hlt, not_goto_t0, t2_reg);
    and g_hd3 (hold_t3,   hlt,     t3_reg);
    or  g_or3 (d3,        avanca_t3, hold_t3);
    ffd ff3 (.clk(clk), .rst_n(rst_n), .d(d3), .q(t3_reg));

    wire avanca_t4, hold_t4;
    and g_av4 (avanca_t4, not_hlt, not_goto_t0, t3_reg);
    and g_hd4 (hold_t4,   hlt,     t4_reg);
    or  g_or4 (d4,        avanca_t4, hold_t4);
    ffd ff4 (.clk(clk), .rst_n(rst_n), .d(d4), .q(t4_reg));

    wire avanca_t5, hold_t5;
    and g_av5 (avanca_t5, not_hlt, not_goto_t0, t4_reg);
    and g_hd5 (hold_t5,   hlt,     t5_reg);
    or  g_or5 (d5,        avanca_t5, hold_t5);
    ffd ff5 (.clk(clk), .rst_n(rst_n), .d(d5), .q(t5_reg));

    wire avanca_t6, hold_t6;
    and g_av6 (avanca_t6, not_hlt, not_goto_t0, t5_reg);
    and g_hd6 (hold_t6,   hlt,     t6_reg);
    or  g_or6 (d6,        avanca_t6, hold_t6);
    ffd ff6 (.clk(clk), .rst_n(rst_n), .d(d6), .q(t6_reg));

    wire avanca_t7, hold_t7;
    and g_av7 (avanca_t7, not_hlt, not_goto_t0, t6_reg);
    and g_hd7 (hold_t7,   hlt,     t7_reg);
    or  g_or7 (d7,        avanca_t7, hold_t7);
    ffd ff7 (.clk(clk), .rst_n(rst_n), .d(d7), .q(t7_reg));
endmodule
```

---

### 2.3. Decodificador de Instruções (`src/decod_inst.v`) – ID 1
* **Função:** Decodifica estruturalmente os 4 bits de operação (`RI[7:4]`) gerando 11 sinais ativos para as instruções do Neander.
* **Código:**
```verilog
`timescale 1ns/1ns

module decod_inst (
    input  wire [3:0] op,
    output wire       nop,
    output wire       sta,
    output wire       lda,
    output wire       add,
    output wire       or_op,
    output wire       and_op,
    output wire       not_op,
    output wire       jmp,
    output wire       jn,
    output wire       jz,
    output wire       hlt
);
    wire not_op3, not_op2, not_op1, not_op0;
    not g_n3 (not_op3, op[3]);
    not g_n2 (not_op2, op[2]);
    not g_n1 (not_op1, op[1]);
    not g_n0 (not_op0, op[0]);

    and g_nop (nop,    not_op3, not_op2, not_op1, not_op0); // 0000 (0x0)
    and g_sta (sta,    not_op3, not_op2, not_op1, op[0]);   // 0001 (0x1)
    and g_lda (lda,    not_op3, not_op2, op[1],   not_op0); // 0010 (0x2)
    and g_add (add,    not_op3, not_op2, op[1],   op[0]);   // 0011 (0x3)
    and g_or  (or_op,  not_op3, op[2],   not_op1, not_op0); // 0100 (0x4)
    and g_and (and_op, not_op3, op[2],   not_op1, op[0]);   // 0101 (0x5)
    and g_not (not_op, not_op3, op[2],   op[1],   not_op0); // 0110 (0x6)
    and g_jmp (jmp,    op[3],   not_op2, not_op1, not_op0); // 1000 (0x8)
    and g_jn  (jn,     op[3],   not_op2, not_op1, op[0]);   // 1001 (0x9)
    and g_jz  (jz,     op[3],   not_op2, op[1],   not_op0); // 1010 (0xA)
    and g_hlt (hlt,    op[3],   op[2],   op[1],   op[0]);   // 1111 (0xF)
endmodule
```

---

### 2.4. Codificador da ULA (`src/codificador_ula.v`) – ID 2
* **Função:** Codifica as 5 linhas de controle de operação da ULA no barramento de seleção `selUAL[2:0]`.
* **Tabela de Codificação:**
  - $Y$ (LDA): `3'b000`
  - $ADD$: `3'b001`
  - $AND$: `3'b010`
  - $OR$: `3'b011`
  - $NOT$: `3'b100`
* **Código:**
```verilog
`timescale 1ns/1ns

module codificador_ula (
    input  wire       ula_y,
    input  wire       ula_add,
    input  wire       ula_and,
    input  wire       ula_or,
    input  wire       ula_not,
    output wire [2:0] selUAL
);
    or  g_sel0 (selUAL[0], ula_add, ula_or);
    or  g_sel1 (selUAL[1], ula_and, ula_or);
    buf g_sel2 (selUAL[2], ula_not);
endmodule
```

---

### 2.5. Unidade de Controle Combinacional (`src/unidade_controle.v`) – ID 11
* **Função:** Implementa a lógica combinacional pura que gera todos os sinais de controle a partir do passo de tempo ativo ($t_0 \dots t_7$), da instrução decodificada e dos flags $N$ e $Z$.
* **Código:**
```verilog
`timescale 1ns/1ns

module unidade_controle (
    input  wire t0, t1, t2, t3, t4, t5, t6, t7,
    input  wire nop, sta, lda, add, or_op, and_op, not_op, jmp, jn, jz,
    input  wire n_flag,
    input  wire z_flag,

    output wire cargaPC,
    output wire incrementaPC,
    output wire sel,
    output wire cargaREM,
    output wire read,
    output wire write,
    output wire cargaRDM,
    output wire cargaAC,
    output wire cargaNZ,
    output wire cargaRI,
    output wire goto_t0,

    output wire ula_y,
    output wire ula_add,
    output wire ula_and,
    output wire ula_or,
    output wire ula_not
);
    wire jn_tomado, jz_tomado;
    and #1 g_jnt (jn_tomado, jn, n_flag);
    and #1 g_jzt (jz_tomado, jz, z_flag);

    wire inst_end2;
    or #1 g_end (inst_end2, sta, lda, add, or_op, and_op, jmp, jn_tomado, jz_tomado);

    wire inst_dado;
    or #1 g_dado (inst_dado, sta, lda, add, or_op, and_op);

    wire inst_ula_mem;
    or #1 g_ulamem (inst_ula_mem, lda, add, or_op, and_op);

    wire jump_valido;
    or  #1 g_jmpval (jump_valido, jmp, jn_tomado, jz_tomado);

    // cargaREM: busca de opcode (t0), busca de endereco do operando (t3), busca de dado (t5)
    wire rem_t3, rem_t5;
    and #1 g_rem3 (rem_t3, t3, inst_end2);
    and #1 g_rem5 (rem_t5, t5, inst_dado);
    or  #1 g_rem  (cargaREM, t0, rem_t3, rem_t5);

    // sel: seleciona RDM como entrada do REM no passo t5 das instrucoes de memoria
    and #1 g_sel (sel, t5, inst_dado);

    // read: leitura do opcode (t1), operando (t4) e dado (t6)
    wire rd_t4, rd_t6;
    and #1 g_rd4 (rd_t4, t4, inst_end2);
    and #1 g_rd6 (rd_t6, t6, inst_ula_mem);
    or  #1 g_rd  (read, t1, rd_t4, rd_t6);

    // write: gravacao na memoria no passo t7 do STA
    and #1 g_wr (write, t7, sta);

    // incrementaPC: avanco em t1 (opcode), t4 (operando) e t3 de desvios nao tomados
    wire t3_inpc, jnnl_jzzl, jnnl, jzzl;
    and #1 g_jnnl (jnnl, jn, ~n_flag);
    and #1 g_jzzl (jzzl, jz, ~z_flag);
    or #1 g_inpc1 (jnnl_jzzl, jnnl, jzzl);
    and #1 g_t3_j (t3_inpc, t3, jnnl_jzzl);
    or  #1 g_incpc (incrementaPC, t1, rd_t4, t3_inpc);

    // cargaPC: carga do salto em t5
    and #1 g_cpc (cargaPC, t5, jump_valido);

    // cargaRI: armazena opcode em t2
    buf #1 g_cri (cargaRI, t2);

    // cargaRDM: copia AC pro RDM em t6 no STA
    and  #1 g_crdm (cargaRDM, t6, sta);

    // cargaAC e cargaNZ: atualiza acumulador e flags
    wire ac_t6, ac_t3_not;
    and #1 g_ct_t6 (ac_t6, t7, inst_dado);
    and #1 g_ac_not (ac_t3_not, t3, not_op);
    or  #1 g_cac (cargaAC, ac_t3_not, ac_t6);
    buf #1 g_cnz (cargaNZ, cargaAC);

    // Comandos da ULA
    and #1 g_uy  (ula_y,   t7, lda);
    and #1 g_uadd(ula_add, t7, add);
    and #1 g_uand(ula_and, t7, and_op);
    and #1 g_uor (ula_or,  t7, or_op);
    buf #1 g_unot(ula_not, ac_t3_not);

    // goto_t0: retorno a t0
    wire fim_t3_nop, fim_t3, fim_t5, fim_t7, fim_t3_jnnljzzl;
    and #1 g_f3nop (fim_t3_nop, t3, nop);
    and #1 g_t3_jnnl_jzzl (fim_t3_jnnljzzl, t3, jnnl_jzzl);
    or  #1 g_f3 (fim_t3, fim_t3_nop, ac_t3_not, fim_t3_jnnljzzl);

    wire inst_jump_qualquer;
    or  #1 g_jmpqualq (inst_jump_qualquer, jmp, jn_tomado, jz_tomado);
    and #1 g_f5 (fim_t5, t5, inst_jump_qualquer);
    and #1 g_f6 (fim_t7, t7, inst_dado);

    or  #1 g_gt0 (goto_t0, fim_t3, fim_t5, fim_t7);
endmodule
```

---

### 2.6. Top-Level de Controle (`src/controle_top.v`)
* **Função:** Encapsula o temporizador, o decodificador, a unidade de controle e o codificador da ULA em uma interface unificada.
* **Código:**
```verilog
`timescale 1ns/1ns

module controle_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] opcode,
    input  wire       flag_n,
    input  wire       flag_z,

    output wire       cargaPC,
    output wire       incrementaPC,
    output wire       sel,
    output wire       cargaREM,
    output wire       read,
    output wire       write,
    output wire       cargaRDM,
    output wire       cargaAC,
    output wire       cargaNZ,
    output wire       cargaRI,
    output wire       goto_t0,

    output wire       ula_y,
    output wire       ula_add,
    output wire       ula_and,
    output wire       ula_or,
    output wire       ula_not,
    output wire [2:0] selUAL,
    output wire [7:0] estado_t
);
    wire t0, t1, t2, t3, t4, t5, t6, t7;
    assign estado_t = {t7, t6, t5, t4, t3, t2, t1, t0};

    wire nop, sta, lda, add, or_op, and_op, not_op, jmp, jn, jz, hlt;

    temporizador u_temp (
        .clk(clk), .rst_n(rst_n), .goto_t0(goto_t0), .hlt(hlt),
        .t0(t0), .t1(t1), .t2(t2), .t3(t3),
        .t4(t4), .t5(t5), .t6(t6), .t7(t7)
    );

    decod_inst u_decod (
        .op(opcode), .nop(nop), .sta(sta), .lda(lda), .add(add),
        .or_op(or_op), .and_op(and_op), .not_op(not_op),
        .jmp(jmp), .jn(jn), .jz(jz), .hlt(hlt)
    );

    unidade_controle u_uc (
        .t0(t0), .t1(t1), .t2(t2), .t3(t3), .t4(t4), .t5(t5), .t6(t6), .t7(t7),
        .nop(nop), .sta(sta), .lda(lda), .add(add), .or_op(or_op),
        .and_op(and_op), .not_op(not_op), .jmp(jmp), .jn(jn), .jz(jz),
        .n_flag(flag_n), .z_flag(flag_z),
        .cargaPC(cargaPC), .incrementaPC(incrementaPC), .sel(sel),
        .cargaREM(cargaREM), .read(read), .write(write),
        .cargaRDM(cargaRDM), .cargaAC(cargaAC), .cargaNZ(cargaNZ),
        .cargaRI(cargaRI), .goto_t0(goto_t0),
        .ula_y(ula_y), .ula_add(ula_add), .ula_and(ula_and),
        .ula_or(ula_or), .ula_not(ula_not)
    );

    codificador_ula u_cod_ula (
        .ula_y(ula_y), .ula_add(ula_add), .ula_and(ula_and),
        .ula_or(ula_or), .ula_not(ula_not), .selUAL(selUAL)
    );
endmodule
```

---

## 3. Datapath e Registradores

### 3.1. Célula Básica de 1 bit e Registrador Genérico (`src/reg8.v`) – ID 7
* **Função:** Implementa um registrador com carga síncrona habilitada e reset assíncrono.
* **Equação do Próximo Estado:** $D_{in} = (\text{load} \land d) \lor (\sim \text{load} \land q)$
* **Código:**
```verilog
`timescale 1ns/1ns

module reg1b (
    input  wire clk,
    input  wire rst_n,
    input  wire load,
    input  wire d,
    output wire q
);
    wire not_load;
    not u_inv (not_load, load);

    wire w_d, w_q;
    and u_and_d (w_d, load, d);
    and u_and_q (w_q, not_load, q);

    wire next_d;
    or u_or (next_d, w_d, w_q);

    ffd u_ff (.clk(clk), .rst_n(rst_n), .d(next_d), .q(q));
endmodule

module reg8 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       load,
    input  wire [7:0] d,
    output wire [7:0] q
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_reg8
            reg1b bit_inst (
                .clk   (clk),
                .rst_n (rst_n),
                .load  (load),
                .d     (d[i]),
                .q     (q[i])
            );
        end
    endgenerate
endmodule
```

---

### 3.2. Registradores Dedicados: AC, RDM, REM, RI
Os módulos dedicados instanciam `reg8` com portas nominais:
* **`src/reg_ac.v`:** Carga por `cargaAC`, entrada da ULA, saída para ULA e display.
* **`src/reg_rdm.v`:** Carga por `load_rdm = cargaRDM | read`, multiplexa entrada entre memória e AC.
* **`src/reg_rem.v`:** Carga por `cargaREM`, entrada do MUX REM, saída para endereço da memória.
* **`src/reg_ri.v`:** Carga por `cargaRI`, entrada do RDM, saída `RI[7:4]` para Unidade de Controle.

---

### 3.3. Registrador de Flags (`src/reg_flags.v`) – ID 9
* **Função:** Armazena os flags de condição $N$ (Negativo) e $Z$ (Zero) gerados pela ULA.
* **Código:**
```verilog
`timescale 1ns/1ns

module reg_flags (
    input  wire clk,
    input  wire rst_n,
    input  wire cargaNZ,
    input  wire in_n,
    input  wire in_z,
    output wire flag_n,
    output wire flag_z
);
    reg1b bit_n (.clk(clk), .rst_n(rst_n), .load(cargaNZ), .d(in_n), .q(flag_n));
    reg1b bit_z (.clk(clk), .rst_n(rst_n), .load(cargaNZ), .d(in_z), .q(flag_z));
endmodule
```

---

### 3.4. Program Counter (`src/pc.v`) – ID 8
* **Função:** Contador estrutural de 8 bits em cascata *Ripple Carry* com suporte a incremento síncrono (`incrementaPC`) e carga paralela (`cargaPC`).
* **Código:**
```verilog
`timescale 1ns/1ns

module pc_slice (
    input  wire clk,
    input  wire rst_n,
    input  wire D,
    input  wire cargaPC,
    input  wire incrementaPC,
    input  wire Cin,
    output wire Cout,
    output wire Q
);
    wire w_q;
    assign Q = w_q;

    wire soma;
    xor g_xor_soma (soma, w_q, Cin);
    and g_and_cout (Cout, w_q, Cin);

    wire n_carga, n_inc;
    not g_ncarga (n_carga, cargaPC);
    not g_ninc   (n_inc, incrementaPC);

    wire termo_carga, termo_inc, termo_hold, d_in;
    and g_tcarga (termo_carga, cargaPC, D);
    and g_tinc   (termo_inc, n_carga, incrementaPC, soma);
    and g_thold  (termo_hold, n_carga, n_inc, w_q);
    or  g_or_d   (d_in, termo_carga, termo_inc, termo_hold);

    ffd u_ffd (.clk(clk), .rst_n(rst_n), .d(d_in), .q(w_q));
endmodule

module pc (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       cargaPC,
    input  wire       incrementaPC,
    input  wire [7:0] D,
    output wire [7:0] Q
);
    wire [7:0] c;
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

### 3.5. Multiplexador 2:1 de 8 bits (`src/mux2x1_8b.v` / `src/mux_rem.v`) – ID 3
* **Função:** Seleciona entre a entrada `d0` (`PC` quando `sel = 0`) e a entrada `d1` (`RDM` quando `sel = 1`).
* **Código:**
```verilog
`timescale 1ns/1ns

module mux2x1_8b (
    input  wire [7:0] d0,
    input  wire [7:0] d1,
    input  wire       sel,
    output wire [7:0] out
);
    assign out = sel ? d1 : d0;
endmodule
```

---

### 3.6. Somador Estrutural (`src/HA.v`, `src/FA.v`, `src/somador.v`)
* **Função:** Ripple Carry Adder de 8 bits construído a partir de Half-Adders e Full-Adders primitivos com portas `xor`, `and` e `or`.
* **Código do Somador de 8 bits:**
```verilog
`timescale 1ns/1ns

module somador (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output wire [7:0] S,
    output wire       Cout
);
    wire [6:0] c;
    HA fa0 (.A(A[0]), .B(B[0]), .S(S[0]), .C(c[0]));
    FA fa1 (.A(A[1]), .B(B[1]), .Cin(c[0]), .S(S[1]), .Cout(c[1]));
    FA fa2 (.A(A[2]), .B(B[2]), .Cin(c[1]), .S(S[2]), .Cout(c[2]));
    FA fa3 (.A(A[3]), .B(B[3]), .Cin(c[2]), .S(S[3]), .Cout(c[3]));
    FA fa4 (.A(A[4]), .B(B[4]), .Cin(c[3]), .S(S[4]), .Cout(c[4]));
    FA fa5 (.A(A[5]), .B(B[5]), .Cin(c[4]), .S(S[5]), .Cout(c[5]));
    FA fa6 (.A(A[6]), .B(B[6]), .Cin(c[5]), .S(S[6]), .Cout(c[6]));
    FA fa7 (.A(A[7]), .B(B[7]), .Cin(c[6]), .S(S[7]), .Cout(Cout));
endmodule
```

---

### 3.7. Unidade Lógica e Aritmética (`src/ula.v`) – ID 4
* **Função:** Executa as 5 operações do Neander e gera os flags $N = S[7]$ e $Z = \sim(\lvert S)$.
* **Código:**
```verilog
`timescale 1ns/1ns

module ula (
    input  wire [7:0] x,
    input  wire [7:0] y,
    input  wire [2:0] selUAL,
    output reg  [7:0] s,
    output wire       flag_n,
    output wire       flag_z
);
    always @(*) begin
        case (selUAL)
            3'b000:  s = y;        // Passa Y (LDA)
            3'b001:  s = x + y;    // ADD
            3'b010:  s = x & y;    // AND
            3'b011:  s = x | y;    // OR
            3'b100:  s = ~x;       // NOT
            default: s = 8'h00;
        endcase
    end

    assign flag_n = s[7];
    assign flag_z = (s == 8'h00);
endmodule
```

---

## 4. Memória e Programa de Validação

### 4.1. Memória RAM/ROM (`src/memoria.v`)
* **Função:** Matriz de 256 bytes de 8 bits com leitura combinacional e escrita síncrona na borda de subida do clock quando `write = 1`.
* **Código:**
```verilog
`timescale 1ns/1ns

module memoria (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       read,
    input  wire       write,
    input  wire [7:0] addr,
    input  wire [7:0] data_in,
    output wire [7:0] data_out
);
    reg [7:0] mem [0:255];
    integer j;

    task inicializar_memoria;
        begin
            for (j = 0; j < 256; j = j + 1) mem[j] = 8'h00;

            // Programa de validacao completo:
            mem[8'h00] = 8'h20; mem[8'h01] = 8'h80; // LDA 0x80 (carrega 5)
            mem[8'h02] = 8'h30; mem[8'h03] = 8'h81; // ADD 0x81 (soma 3 = 8)
            mem[8'h04] = 8'h10; mem[8'h05] = 8'h82; // STA 0x82 (armazena 8)
            mem[8'h06] = 8'h60;                     // NOT (~8 = 0xF7, N=1, Z=0)
            mem[8'h07] = 8'h90; mem[8'h08] = 8'h0B; // JN 0x0B (salta pois N=1)
            mem[8'h09] = 8'hF0;                     // HLT (trap caso falhe)
            mem[8'h0B] = 8'h50; mem[8'h0C] = 8'h83; // AND 0x83 (F7 & 0 = 0, Z=1)
            mem[8'h0D] = 8'hA0; mem[8'h0E] = 8'h11; // JZ 0x11 (salta pois Z=1)
            mem[8'h0F] = 8'hF0;                     // HLT (trap caso falhe)
            mem[8'h11] = 8'h40; mem[8'h12] = 8'h84; // OR 0x84 (0 | 0xAA = 0xAA)
            mem[8'h13] = 8'hF0;                     // HLT (fim com sucesso)

            // Dados:
            mem[8'h80] = 8'h05; mem[8'h81] = 8'h03; mem[8'h82] = 8'h00;
            mem[8'h83] = 8'h00; mem[8'h84] = 8'hAA;
        end
    endtask

    initial inicializar_memoria();

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) inicializar_memoria();
        else if (write) mem[addr] <= data_in;
    end

    assign data_out = (read) ? mem[addr] : 8'h00;
endmodule
```

---

## 5. Interface com a Placa Altera DE0

### 5.1. Divisor de Clock Estrutural (`src/divisor_clock.v`) – ID 5
* **Função:** Cascata de 24 Flip-Flops D conectados em modo toggle ($D = \sim Q$), dividindo o clock de 50 MHz da placa para aproximadamente $2.98\text{ Hz}$ ($50\text{ MHz} / 2^{24}$).

### 5.2. Seletor de Modo RUN / STEP (`src/run_step_mode.v`) – ID 6
* **Função:** Comuta estruturalmente a fonte do clock do Neander:
  - `SW0 = 1`: Modo **RUN** contínuo (clock do divisor).
  - `SW0 = 0`: Modo **STEP** manual (cada clique no `BUTTON1` gera uma borda de clock).

### 5.3. Decodificador Hexadecimal para 7 Segmentos (`src/bcd_7seg.v`) – ID 12
* **Função:** Decodificador estrutural de mintermos 4:16 e matriz OR ativa em nível baixo (`0 = aceso`, `1 = apagado`).
* **Código:**
```verilog
`timescale 1ns/1ns

module bcd_7seg (
    input  wire [3:0] in,
    output wire [6:0] seg
);
    wire n3, n2, n1, n0;
    not g_n3 (n3, in[3]); not g_n2 (n2, in[2]);
    not g_n1 (n1, in[1]); not g_n0 (n0, in[0]);

    wire m0, m1, m2, m3, m4, m5, m6, m7;
    wire m8, m9, m10, m11, m12, m13, m14, m15;

    and g_m0  (m0,  n3,    n2,    n1,    n0);
    and g_m1  (m1,  n3,    n2,    n1,    in[0]);
    and g_m2  (m2,  n3,    n2,    in[1], n0);
    and g_m3  (m3,  n3,    n2,    in[1], in[0]);
    and g_m4  (m4,  n3,    in[2], n1,    n0);
    and g_m5  (m5,  n3,    in[2], n1,    in[0]);
    and g_m6  (m6,  n3,    in[2], in[1], n0);
    and g_m7  (m7,  n3,    in[2], in[1], in[0]);
    and g_m8  (m8,  in[3], n2,    n1,    n0);
    and g_m9  (m9,  in[3], n2,    n1,    in[0]);
    and g_m10 (m10, in[3], n2,    in[1], n0);
    and g_m11 (m11, in[3], n2,    in[1], in[0]);
    and g_m12 (m12, in[3], in[2], n1,    n0);
    and g_m13 (m13, in[3], in[2], n1,    in[0]);
    and g_m14 (m14, in[3], in[2], in[1], n0);
    and g_m15 (m15, in[3], in[2], in[1], in[0]);

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

## 6. Módulo Top-Level do Neander (`src/neander_top.v`)

O top-level integra todos os subsistemas em um único bloco sintetizável pronto para compilação no Quartus II.

```verilog
`timescale 1ns/1ns

module neander_top #(
    parameter SIMULATION = 0
)(
    input  wire       clk_50MHz,
    input  wire       rst_n,
    input  wire       btn_step_n,
    input  wire       modo_run,

    output wire       led_n,
    output wire       led_z,
    output wire       led_hlt,

    output wire [6:0] hex0,
    output wire [6:0] hex1,
    output wire [6:0] hex2,
    output wire [6:0] hex3
);
    // 1. Clock
    wire clk_div_2Hz;
    divisor_clock u_divisor (
        .clk_50MHz (clk_50MHz),
        .rst_n     (rst_n),
        .clk_2Hz   (clk_div_2Hz)
    );

    wire clk_auto_eff = (SIMULATION) ? clk_50MHz : clk_div_2Hz;
    wire clk_cpu;
    run_step_mode u_run_step (
        .clk_auto   (clk_auto_eff),
        .btn_step_n (btn_step_n),
        .modo_run   (modo_run),
        .clk_out    (clk_cpu)
    );

    // 2. Fios do Datapath e Controle
    wire       cargaPC, incrementaPC, sel_mux_rem, cargaREM;
    wire       mem_read, mem_write, cargaRDM_uc, cargaAC, cargaNZ, cargaRI, goto_t0;
    wire [2:0] selUAL;
    wire [7:0] estado_t;
    wire [7:0] pc_out, rem_in, rem_out, mem_data_out, rdm_in, rdm_out, ri_out, ac_out, ula_out;
    wire       ula_flag_n, ula_flag_z, flag_n, flag_z;

    // 3. Controle
    controle_top u_controle (
        .clk          (clk_cpu),
        .rst_n        (rst_n),
        .opcode       (ri_out[7:4]),
        .flag_n       (flag_n),
        .flag_z       (flag_z),
        .cargaPC      (cargaPC),
        .incrementaPC (incrementaPC),
        .sel          (sel_mux_rem),
        .cargaREM     (cargaREM),
        .read         (mem_read),
        .write        (mem_write),
        .cargaRDM     (cargaRDM_uc),
        .cargaAC      (cargaAC),
        .cargaNZ      (cargaNZ),
        .cargaRI      (cargaRI),
        .goto_t0      (goto_t0),
        .ula_y        (),
        .ula_add      (),
        .ula_and      (),
        .ula_or       (),
        .ula_not      (),
        .selUAL       (selUAL),
        .estado_t     (estado_t)
    );

    // 4. Datapath
    pc u_pc (
        .clk(clk_cpu), .rst_n(rst_n), .cargaPC(cargaPC),
        .incrementaPC(incrementaPC), .D(rdm_out), .Q(pc_out)
    );

    mux2x1_8b u_mux_rem (
        .d0(pc_out), .d1(rdm_out), .sel(sel_mux_rem), .out(rem_in)
    );

    reg_rem u_rem (
        .clk(clk_cpu), .rst_n(rst_n), .cargaREM(cargaREM), .d(rem_in), .q(rem_out)
    );

    memoria u_mem (
        .clk(clk_cpu), .rst_n(rst_n), .read(mem_read), .write(mem_write),
        .addr(rem_out), .data_in(rdm_out), .data_out(mem_data_out)
    );

    wire load_rdm;
    or g_load_rdm (load_rdm, cargaRDM_uc, mem_read);

    mux2x1_8b u_mux_rdm (
        .d0(mem_data_out), .d1(ac_out), .sel(cargaRDM_uc), .out(rdm_in)
    );

    reg_rdm u_rdm (
        .clk(clk_cpu), .rst_n(rst_n), .cargaRDM(load_rdm), .d(rdm_in), .q(rdm_out)
    );

    reg_ri u_ri (
        .clk(clk_cpu), .rst_n(rst_n), .cargaRI(cargaRI), .d(rdm_out), .q(ri_out)
    );

    ula u_ula (
        .x(ac_out), .y(rdm_out), .selUAL(selUAL), .s(ula_out),
        .flag_n(ula_flag_n), .flag_z(ula_flag_z)
    );

    reg_flags u_flags (
        .clk(clk_cpu), .rst_n(rst_n), .cargaNZ(cargaNZ),
        .in_n(ula_flag_n), .in_z(ula_flag_z), .flag_n(flag_n), .flag_z(flag_z)
    );

    reg_ac u_ac (
        .clk(clk_cpu), .rst_n(rst_n), .cargaAC(cargaAC), .d(ula_out), .q(ac_out)
    );

    // 5. Interface com a DE0
    assign led_n = flag_n;
    assign led_z = flag_z;

    wire hlt_ativo;
    and g_hlt (hlt_ativo, ri_out[7], ri_out[6], ri_out[5], ri_out[4]);
    assign led_hlt = hlt_ativo;

    bcd_7seg disp_pc_alto  (.in(pc_out[7:4]), .seg(hex3));
    bcd_7seg disp_pc_baixo (.in(pc_out[3:0]), .seg(hex2));
    bcd_7seg disp_ac_alto  (.in(ac_out[7:4]), .seg(hex1));
    bcd_7seg disp_ac_baixo (.in(ac_out[3:0]), .seg(hex0));
endmodule
```

---

## 7. Mapeamento de Pinos da FPGA Altera DE0 (`neander.qsf`)

| Sinal no Top-Level | Função | Pino Altera DE0 (`EP3C16F484C6`) |
| :--- | :--- | :---: |
| `clk_50MHz` | Clock oscilador onboard 50 MHz | `PIN_G21` |
| `rst_n` | Reset Geral Assíncrono (`BUTTON0`) | `PIN_H2` |
| `btn_step_n` | Pulso manual de clock STEP (`BUTTON1`) | `PIN_G3` |
| `modo_run` | Chave seletora RUN (1) vs STEP (0) (`SW0`) | `PIN_J6` |
| `led_n` | Flag Negativo (`LEDG0`) | `PIN_J1` |
| `led_z` | Flag Zero (`LEDG1`) | `PIN_J2` |
| `led_hlt` | Parada de Execução HLT (`LEDG5`) | `PIN_J3` |
| `hex0[6:0]` | Acumulador dígito menos significativo (a..g) | `PIN_F13, F12, G12, H13, H12, F11, E11` |
| `hex1[6:0]` | Acumulador dígito mais significativo (a..g) | `PIN_A15, E14, B14, A14, C13, B13, A13` |
| `hex2[6:0]` | PC dígito menos significativo (a..g) | `PIN_F14, B17, A17, E15, B16, A16, D15` |
| `hex3[6:0]` | PC dígito mais significativo (a..g) | `PIN_G15, D19, C19, B19, A19, F15, B18` |

---

## 8. Guia de Simulação com Makefile

Para rodar todos os testes do projeto de forma automatizada:

```bash
cd /home/schons/Documentos/facul/CD/CircuitosDigitais/neander
make test
```

Para rodar um teste individual e inspecionar a forma de onda:
```bash
make tb_neander
make wave VCD=tb/tb_neander.vcd
```
