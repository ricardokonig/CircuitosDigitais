`timescale 1ns/1ns

// ============================================================================
// ID 7: Registrador Estrutural de 1 bit com Carga Sincrona e Reset Assincrono
// ============================================================================
// Celula basica composta por:
//  - MUX 2:1 estrutural (portas NOT, AND, OR):
//      next_d = (load & d) | (~load & q)
//  - Flip-Flop D estrutural (ffd.v) com reset assincrono ativo em 0.
// ============================================================================
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

    ffd u_ff (
        .clk   (clk),
        .rst_n (rst_n),
        .d     (next_d),
        .q     (q)
    );
endmodule

// ============================================================================
// ID 7: Registrador Generico de 8 bits Estrutural
// ============================================================================
// Utilizado para a implementacao de AC, RDM, REM e RI no processador Neander.
// ============================================================================
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
