`timescale 1ns/1ns

// ============================================================================
// Registrador Acumulador (AC) - Processador Neander
// ============================================================================
// Registrador de 8 bits responsavel por armazenar o operando acumulado e
// receber os resultados gerados pela ULA.
//
// Conexoes no Neander:
//  - clk: Clock efetivo do sistema (Run/Step Mode)
//  - rst_n: Reset assincrono ativo em 0 (BUTTON0)
//  - cargaAC: Habilitacao de carga sincrona (Unidade de Controle)
//  - d[7:0]: Barramento de entrada (saida S da ULA)
//  - q[7:0]: Saida conectada a entrada X da ULA, ao RDM (instrucao STA) e
//            aos displays HEX1 e HEX0
// ============================================================================
module reg_ac (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       cargaAC,
    input  wire [7:0] d,
    output wire [7:0] q
);
    reg8 u_ac (
        .clk   (clk),
        .rst_n (rst_n),
        .load  (cargaAC),
        .d     (d),
        .q     (q)
    );
endmodule
