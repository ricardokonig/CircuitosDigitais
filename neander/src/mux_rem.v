`timescale 1ns/1ns

/*
 * ============================================================================
 * Modulo: mux_rem (ID 3 - MUX do REM com Portas Semanticas do Neander)
 * ============================================================================
 * Descricao:
 *   Multiplexador do Registrador de Endereco de Memoria (REM) do Neander.
 *   Encapsula o modulo basico 'mux2x1_8b' conectando os sinais nominais
 *   da arquitetura Neander:
 *     - sel = 0: envia o valor do Program Counter (pc) para o rem
 *     - sel = 1: envia o valor do Registrador de Dados (rdm) para o rem
 *
 * Entradas:
 *   - pc  [7:0] : Endereco vindo do Program Counter (PC)
 *   - rdm [7:0] : Endereco do operando vindo do RDM
 *   - sel       : Sinal de controle gerado pela Unidade de Controle
 *
 * Saidas:
 *   - rem [7:0] : Barramento de endereco conectado a entrada do REM
 * ============================================================================
 */

module mux_rem (
    input  wire [7:0] pc,   // Barramento vindo do Program Counter
    input  wire [7:0] rdm,  // Barramento vindo do Registrador de Dados
    input  wire       sel,  // Sinal de selecao (0 = PC, 1 = RDM)
    output wire [7:0] rem   // Endereco selecionado para a entrada do REM
);

    // Instancia do multiplexador basico 2x1 de 8 bits
    mux2x1_8b u_mux (
        .d0(pc),
        .d1(rdm),
        .sel(sel),
        .out(rem)
    );

endmodule
