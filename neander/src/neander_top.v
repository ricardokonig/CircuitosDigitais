`timescale 1ns/1ns

// ============================================================================
// Top-Level do Processador Neander Completo
// ============================================================================
// Integra:
//  - Divisor de Clock Estrutural (ID 5)
//  - Run/Step Mode (ID 6)
//  - Unidade de Controle e Temporizador (controle_top: IDs 1, 2, 10, 11)
//  - Program Counter (pc: ID 8)
//  - MUX do REM (mux_rem / mux2x1_8b: ID 3)
//  - Registradores Estruturais AC, RDM, REM, RI (reg_ac, reg_rdm, reg_rem, reg_ri: ID 7)
//  - ULA de 8 bits (ula: ID 4)
//  - Registrador de Flags N e Z (reg_flags: ID 9)
//  - Memoria de 256 bytes (memoria: ROM/RAM)
//  - 4 Decodificadores Hexadecimal para 7 Segmentos (bcd_7seg: ID 12)
//
// Mapeamento na Placa Altera DE0 (Cyclone III EP3C16F484C6):
//  - clk_50MHz  : PIN_G21 (Clock de 50 MHz da placa)
//  - rst_n      : PIN_H2  (BUTTON0 - Reset assincrono ativo em 0)
//  - btn_step_n : PIN_G3  (BUTTON1 - Avanco manual no modo STEP)
//  - modo_run   : PIN_J6  (SW0 - 1 = RUN continuo, 0 = STEP manual)
//  - led_n      : PIN_J1  (LEDG0 - Flag Negativo)
//  - led_z      : PIN_J2  (LEDG1 - Flag Zero)
//  - led_hlt    : PIN_J3  (LEDG5 - Indicador de Parada HLT)
//  - hex0       : HEX0 (AC baixo, seg[6:0])
//  - hex1       : HEX1 (AC alto,  seg[6:0])
//  - hex2       : HEX2 (PC baixo, seg[6:0])
//  - hex3       : HEX3 (PC alto,  seg[6:0])
// ============================================================================
module neander_top #(
    parameter SIMULATION = 0 // Se 1, bypassa divisor de 24 bits para simular rapidamente
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

    // ========================================================================
    // 1. Geracao e Selecao do Clock (ID 5 e ID 6)
    // ========================================================================
    wire clk_div_2Hz;
    divisor_clock u_divisor (
        .clk_50MHz (clk_50MHz),
        .rst_n     (rst_n),
        .clk_2Hz   (clk_div_2Hz)
    );

    wire clk_auto_eff;
    assign clk_auto_eff = (SIMULATION) ? clk_50MHz : clk_div_2Hz;

    wire clk_cpu;
    run_step_mode u_run_step (
        .clk_auto   (clk_auto_eff),
        .btn_step_n (btn_step_n),
        .modo_run   (modo_run),
        .clk_out    (clk_cpu)
    );

    // ========================================================================
    // 2. Fios de Controle e Barramentos
    // ========================================================================
    // Sinais de controle vindos da Unidade de Controle
    wire       cargaPC;
    wire       incrementaPC;
    wire       sel_mux_rem;
    wire       cargaREM;
    wire       mem_read;
    wire       mem_write;
    wire       cargaRDM_uc;
    wire       cargaAC;
    wire       cargaNZ;
    wire       cargaRI;
    wire       goto_t0;
    wire [2:0] selUAL;
    wire [7:0] estado_t;

    // Barramentos de dados do Datapath
    wire [7:0] pc_out;
    wire [7:0] rem_in;
    wire [7:0] rem_out;
    wire [7:0] mem_data_out;
    wire [7:0] rdm_in;
    wire [7:0] rdm_out;
    wire [7:0] ri_out;
    wire [7:0] ac_out;
    wire [7:0] ula_out;
    wire       ula_flag_n;
    wire       ula_flag_z;
    wire       flag_n;
    wire       flag_z;

    // ========================================================================
    // 3. Unidade de Controle e Temporizador (controle_top)
    // ========================================================================
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

    // ========================================================================
    // 4. Datapath Neander
    // ========================================================================

    // 4.1 Program Counter (PC: ID 8)
    pc u_pc (
        .clk          (clk_cpu),
        .rst_n        (rst_n),
        .cargaPC      (cargaPC),
        .incrementaPC (incrementaPC),
        .D            (rdm_out),
        .Q            (pc_out)
    );

    // 4.2 MUX do REM (ID 3): sel=0 seleciona PC, sel=1 seleciona RDM
    mux2x1_8b u_mux_rem (
        .d0  (pc_out),
        .d1  (rdm_out),
        .sel (sel_mux_rem),
        .out (rem_in)
    );

    // 4.3 Registrador de Endereco de Memoria (REM: ID 7)
    reg_rem u_rem (
        .clk      (clk_cpu),
        .rst_n    (rst_n),
        .cargaREM (cargaREM),
        .d        (rem_in),
        .q        (rem_out)
    );

    // 4.4 Memoria (ROM/RAM de 256 bytes)
    memoria u_mem (
        .clk      (clk_cpu),
        .rst_n    (rst_n),
        .read     (mem_read),
        .write    (mem_write),
        .addr     (rem_out),
        .data_in  (rdm_out),
        .data_out (mem_data_out)
    );

    // 4.5 MUX e Carga do RDM:
    //  - Na leitura da memoria: recebe mem_data_out habilitado por mem_read.
    //  - Na instrucao STA (t6): recebe ac_out habilitado por cargaRDM_uc.
    wire load_rdm;
    or g_load_rdm (load_rdm, cargaRDM_uc, mem_read);

    mux2x1_8b u_mux_rdm (
        .d0  (mem_data_out),
        .d1  (ac_out),
        .sel (cargaRDM_uc),
        .out (rdm_in)
    );

    reg_rdm u_rdm (
        .clk      (clk_cpu),
        .rst_n    (rst_n),
        .cargaRDM (load_rdm),
        .d        (rdm_in),
        .q        (rdm_out)
    );

    // 4.6 Registrador de Instrucao (RI: ID 7)
    reg_ri u_ri (
        .clk     (clk_cpu),
        .rst_n   (rst_n),
        .cargaRI (cargaRI),
        .d       (rdm_out),
        .q       (ri_out)
    );

    // 4.7 ULA (ID 4)
    ula u_ula (
        .x      (ac_out),
        .y      (rdm_out),
        .selUAL (selUAL),
        .s      (ula_out),
        .flag_n (ula_flag_n),
        .flag_z (ula_flag_z)
    );

    // 4.8 Registrador de Flags (ID 9)
    reg_flags u_flags (
        .clk     (clk_cpu),
        .rst_n   (rst_n),
        .cargaNZ (cargaNZ),
        .in_n    (ula_flag_n),
        .in_z    (ula_flag_z),
        .flag_n  (flag_n),
        .flag_z  (flag_z)
    );

    // 4.9 Registrador Acumulador (AC: ID 7)
    reg_ac u_ac (
        .clk     (clk_cpu),
        .rst_n   (rst_n),
        .cargaAC (cargaAC),
        .d       (ula_out),
        .q       (ac_out)
    );

    // ========================================================================
    // 5. Interface com a Placa Altera DE0
    // ========================================================================

    // 5.1 LEDs de Status
    assign led_n   = flag_n;
    assign led_z   = flag_z;

    // HLT ativo quando RI decodifica opcode 1111 (0xF)
    wire hlt_ativo;
    and g_hlt (hlt_ativo, ri_out[7], ri_out[6], ri_out[5], ri_out[4]);
    assign led_hlt = hlt_ativo;

    // 5.2 Displays de 7 Segmentos Estruturais (ID 12)
    // HEX3 e HEX2: Program Counter (PC)
    bcd_7seg disp_pc_alto  (.in(pc_out[7:4]), .seg(hex3));
    bcd_7seg disp_pc_baixo (.in(pc_out[3:0]), .seg(hex2));

    // HEX1 e HEX0: Acumulador (AC)
    bcd_7seg disp_ac_alto  (.in(ac_out[7:4]), .seg(hex1));
    bcd_7seg disp_ac_baixo (.in(ac_out[3:0]), .seg(hex0));

endmodule
