`timescale 1ns/1ns

// decodifica os 4 bits de opcode (RI[7:4]) nas 11 instrucoes do Neander
module decod_inst (
    input  wire [3:0] op,
    output wire nop,
    output wire sta,
    output wire lda,
    output wire add,
    output wire or_op,
    output wire and_op,
    output wire not_op,
    output wire jmp,
    output wire jn,
    output wire jz,
    output wire hlt
);
    // inversores pra montar os mintermos
    wire nop3, nop2, nop1, nop0;
    not #1 inv3 (nop3, op[3]);
    not #1 inv2 (nop2, op[2]);
    not #1 inv1 (nop1, op[1]);
    not #1 inv0 (nop0, op[0]);

    // mintermo de cada instrucao com portas AND de 4 entradas
    and #1 a_nop (nop,    nop3, nop2, nop1, nop0); // 0x0
    and #1 a_sta (sta,    nop3, nop2, nop1, op[0]);// 0x1
    and #1 a_lda (lda,    nop3, nop2, op[1], nop0);// 0x2
    and #1 a_add (add,    nop3, nop2, op[1], op[0]);// 0x3
    and #1 a_or  (or_op,  nop3, op[2], nop1, nop0);// 0x4
    and #1 a_and (and_op, nop3, op[2], nop1, op[0]);// 0x5
    and #1 a_not (not_op, nop3, op[2], op[1], nop0);// 0x6
    and #1 a_jmp (jmp,    op[3], nop2, nop1, nop0);// 0x8
    and #1 a_jn  (jn,     op[3], nop2, nop1, op[0]);// 0x9
    and #1 a_jz  (jz,     op[3], nop2, op[1], nop0);// 0xA
    and #1 a_hlt (hlt,    op[3], op[2], op[1], op[0]);// 0xF

endmodule
