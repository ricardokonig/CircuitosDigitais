`timescale 1ns/1ns

/*
 * ============================================================================
 * Modulo: mux2x1_8b (ID 3 - MUX do REM)
 * ============================================================================
 * Descricao:
 *   Multiplexador 2 para 1 de 8 bits combinacional.
 *   Utilizado no datapath do processador Neander para selecionar a fonte do
 *   Registrador de Endereco de Memoria (REM):
 *     - sel = 0: seleciona a entrada d0 (Program Counter - PC)
 *     - sel = 1: seleciona a entrada d1 (Registrador de Dados da Memoria - RDM)
 *
 * Entradas:
 *   - d0  [7:0] : Entrada 0 (conectada a saida do PC)
 *   - d1  [7:0] : Entrada 1 (conectada a saida do RDM)
 *   - sel       : Seletor (gerado pela Unidade de Controle)
 *
 * Saidas:
 *   - out [7:0] : Saida de 8 bits direcionada a entrada de dados do REM
 * ============================================================================
 */

module mux2x1_8b (
    input  wire [7:0] d0,   // Entrada 0 (sel = 0 -> PC)
    input  wire [7:0] d1,   // Entrada 1 (sel = 1 -> RDM)
    input  wire       sel,  // Seletor: 0 seleciona d0, 1 seleciona d1
    output wire [7:0] out   // Saida de 8 bits para o REM
);

    // Atribuicao combinacional direta (inferencia otimizada de multiplexador)
    assign out = sel ? d1 : d0;

endmodule
