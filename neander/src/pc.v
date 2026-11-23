`timescale 1ns/1ns

// ============================================================================
// ID 8: Fatia de 1 bit do Program Counter (PC Slice)
// ============================================================================
// Atende a restricao ESTRUTURAL exigida para o Neander:
//  1. Meio-somador estrutural (portas XOR e AND) para o incremento.
//  2. Logica MUX de selecao do proximo estado (portas NOT, AND, OR):
//     - Prioridade 1: Carga paralela (cargaPC = 1) -> D
//     - Prioridade 2: Incremento (incrementaPC = 1) -> Q + Cin
//     - Prioridade 3: Manter (hold) -> Q
//  3. Armazenamento via flip-flop D com reset assincrono ativo em 0 (ffd.v).
// ============================================================================
module pc_slice (
    input  wire clk,
    input  wire rst_n,
    input  wire D,              // Dado de entrada para carga paralela
    input  wire cargaPC,        // Habilita carga de salto
    input  wire incrementaPC,   // Habilita incremento
    input  wire Cin,            // Carry-in do incremento
    output wire Cout,           // Carry-out para o bit seguinte
    output wire Q               // Saida do bit atual
);
    wire w_q;
    assign Q = w_q;

    // Meio-somador para o incremento
    wire soma;
    xor g_xor_soma (soma, w_q, Cin);
    and g_and_cout (Cout, w_q, Cin);

    // MUX de selecao do proximo estado:
    // Prioridade: cargaPC > incrementaPC > manter
    // d_in = (cargaPC & D) | (~cargaPC & incrementaPC & soma) | (~cargaPC & ~incrementaPC & w_q)
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
// ID 8: Top-Level do Program Counter de 8 bits (PC)
// ============================================================================
// Registrador contador de 8 bits estrutural em cascata Ripple Carry.
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

    // Bit 0: Cin eh ativado diretamente pelo sinal incrementaPC
    pc_slice bit0 (.clk(clk), .rst_n(rst_n), .D(D[0]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(incrementaPC), .Cout(c[0]), .Q(Q[0]));
    pc_slice bit1 (.clk(clk), .rst_n(rst_n), .D(D[1]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[0]),          .Cout(c[1]), .Q(Q[1]));
    pc_slice bit2 (.clk(clk), .rst_n(rst_n), .D(D[2]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[1]),          .Cout(c[2]), .Q(Q[2]));
    pc_slice bit3 (.clk(clk), .rst_n(rst_n), .D(D[3]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[2]),          .Cout(c[3]), .Q(Q[3]));
    pc_slice bit4 (.clk(clk), .rst_n(rst_n), .D(D[4]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[3]),          .Cout(c[4]), .Q(Q[4]));
    pc_slice bit5 (.clk(clk), .rst_n(rst_n), .D(D[5]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[4]),          .Cout(c[5]), .Q(Q[5]));
    pc_slice bit6 (.clk(clk), .rst_n(rst_n), .D(D[6]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[5]),          .Cout(c[6]), .Q(Q[6]));
    pc_slice bit7 (.clk(clk), .rst_n(rst_n), .D(D[7]), .cargaPC(cargaPC), .incrementaPC(incrementaPC), .Cin(c[6]),          .Cout(c[7]), .Q(Q[7]));

endmodule
