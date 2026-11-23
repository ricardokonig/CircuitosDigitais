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

    // Bit N (Negativo) usando a celula basica estrutural reg1b
    reg1b bit_n (
        .clk   (clk),
        .rst_n (rst_n),
        .load  (cargaNZ),
        .d     (in_n),
        .q     (flag_n)
    );

    // Bit Z (Zero) usando a celula basica estrutural reg1b
    reg1b bit_z (
        .clk   (clk),
        .rst_n (rst_n),
        .load  (cargaNZ),
        .d     (in_z),
        .q     (flag_z)
    );

endmodule
