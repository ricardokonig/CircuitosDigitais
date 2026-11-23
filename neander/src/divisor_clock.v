`timescale 1ns/1ns

// ============================================================================
// ID 5: Divisor de Clock Estrutural (50 MHz -> ~2.98 Hz)
// ============================================================================
// Especificacao:
//  - Recebe clock de 50 MHz da placa Altera DE0 (PIN_G21).
//  - Gera um clock lento de aproximadamente 2 Hz (~2.98 Hz com 24 estagios).
//  - Restricao: 100% ESTRUTURAL (construido exclusivamente com celulas ffd e
//    portas logicas primitivas, sem contadores comportamentais).
// ============================================================================

// ----------------------------------------------------------------------------
// Estagio individual divisor por 2 (Toggle Flip-Flop estrutural com ffd)
// ----------------------------------------------------------------------------
module div_stage (
    input  wire clk_in,
    input  wire rst_n,
    output wire clk_out
);
    wire not_q;

    // Realimenta a saida negada na entrada D (D = ~Q)
    not g_inv (not_q, clk_out);

    // Flip-flop D com reset assincrono ativo em 0
    ffd u_ff (
        .clk   (clk_in),
        .rst_n (rst_n),
        .d     (not_q),
        .q     (clk_out)
    );

endmodule

// ----------------------------------------------------------------------------
// Bloco de 8 estagios de divisao em cascata (Divisor por 2^8 = 256)
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Top-Level do Divisor de Clock Estrutural (24 estagios: 50 MHz -> ~2.98 Hz)
// ----------------------------------------------------------------------------
module divisor_clock (
    input  wire clk_50MHz,    // Clock de 50 MHz da FPGA (PIN_G21)
    input  wire rst_n,        // Reset assincrono ativo em 0 (BUTTON0)
    output wire clk_2Hz       // Clock dividido de ~2.98 Hz
);
    wire clk_div8, clk_div16;

    // 1º bloco de 8 estagios: 50 MHz / 256 = 195.3125 kHz
    div_8stages b1 (
        .clk_in  (clk_50MHz),
        .rst_n   (rst_n),
        .clk_out (clk_div8)
    );

    // 2º bloco de 8 estagios: 195.3125 kHz / 256 = 762.939 Hz
    div_8stages b2 (
        .clk_in  (clk_div8),
        .rst_n   (rst_n),
        .clk_out (clk_div16)
    );

    // 3º bloco de 8 estagios: 762.939 Hz / 256 = ~2.9802 Hz (~3 Hz)
    div_8stages b3 (
        .clk_in  (clk_div16),
        .rst_n   (rst_n),
        .clk_out (clk_2Hz)
    );

endmodule
