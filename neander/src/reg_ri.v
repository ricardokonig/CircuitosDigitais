`timescale 1ns/1ns

// ============================================================================
// Registrador de Instrucao (RI) - Processador Neander
// ============================================================================
// Registrador de 8 bits responsavel por armazenar o byte da instrucao corrente,
// carregado durante o passo de busca (t2).
//
// Conexoes no Neander:
//  - clk: Clock efetivo do sistema (Run/Step Mode)
//  - rst_n: Reset assincrono ativo em 0 (BUTTON0)
//  - cargaRI: Habilitacao de carga sincrona no ciclo t2 (Unidade de Controle)
//  - d[7:0]: Byte de instrucao lido da memoria
//  - q[7:0]: Byte armazenado, onde q[7:4] e entregue ao decodificador de instrucoes
// ============================================================================
module reg_ri (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       cargaRI,
    input  wire [7:0] d,
    output wire [7:0] q
);
    reg8 u_ri (
        .clk   (clk),
        .rst_n (rst_n),
        .load  (cargaRI),
        .d     (d),
        .q     (q)
    );
endmodule
