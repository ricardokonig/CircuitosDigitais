`timescale 1ns/1ns

// converte os 5 comandos da ULA no seletor de 3 bits (selUAL)
module codificador_ula (
    input  wire ula_y,   // 3'b000 (passa Y / LDA)
    input  wire ula_add, // 3'b001 (soma)
    input  wire ula_and, // 3'b010 (E logico)
    input  wire ula_or,  // 3'b011 (OU logico)
    input  wire ula_not, // 3'b100 (inverte X)
    output wire [2:0] selUAL
);
    // bit 0 fica em 1 no ADD (001) e OR (011)
    or  #1 g_sel0 (selUAL[0], ula_add, ula_or);

    // bit 1 fica em 1 no AND (010) e OR (011)
    or  #1 g_sel1 (selUAL[1], ula_and, ula_or);

    // bit 2 fica em 1 no NOT (100)
    buf #1 g_sel2 (selUAL[2], ula_not);

endmodule
