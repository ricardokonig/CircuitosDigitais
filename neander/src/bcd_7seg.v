`timescale 1ns/1ns

// ============================================================================
// ID 12: Decodificador Hexadecimal para 7 Segmentos (Estrutural)
// ============================================================================
// Converte um valor hexadecimal de 4 bits (0 a F) para acionamento dos displays
// de 7 segmentos da placa Altera DE0 (EP3C16F484C6).
//
// Restricao: Estrutural (decodificador 4:16 de mintermos + matriz OR)
// Padrao DE0: Ativo em nivel baixo (0 = aceso, 1 = apagado)
// Saidas: seg[0]=a, seg[1]=b, seg[2]=c, seg[3]=d, seg[4]=e, seg[5]=f, seg[6]=g
// ============================================================================
module bcd_7seg (
    input  wire [3:0] in,
    output wire [6:0] seg
);

    // 1. Inversores dos 4 bits de entrada
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

    // 3. Matriz OR para cada segmento (nivel 1 apaga o segmento no display DE0)
    // seg[0] = a: apagado em 1, 4, 11 (B), 13 (D)
    or g_sega (seg[0], m1, m4, m11, m13);

    // seg[1] = b: apagado em 5, 6, 11 (B), 12 (C), 14 (E), 15 (F)
    or g_segb (seg[1], m5, m6, m11, m12, m14, m15);

    // seg[2] = c: apagado em 2, 12 (C), 14 (E), 15 (F)
    or g_segc (seg[2], m2, m12, m14, m15);

    // seg[3] = d: apagado em 1, 4, 7, 10 (A), 15 (F)
    or g_segd (seg[3], m1, m4, m7, m10, m15);

    // seg[4] = e: apagado em 1, 3, 4, 5, 7, 9
    or g_sege (seg[4], m1, m3, m4, m5, m7, m9);

    // seg[5] = f: apagado em 1, 2, 3, 7, 13 (D)
    or g_segf (seg[5], m1, m2, m3, m7, m13);

    // seg[6] = g: apagado em 0, 1, 7, 12 (C)
    or g_segg (seg[6], m0, m1, m7, m12);

endmodule
