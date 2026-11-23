`timescale 1ns/1ns

// ============================================================================
// Registrador de Endereco da Memoria (REM) - Processador Neander
// ============================================================================
// Registrador de 8 bits responsavel por armazenar e fornecer o endereco da
// posicao de memoria a ser lida ou escrita.
//
// Conexoes no Neander:
//  - clk: Clock efetivo do sistema (Run/Step Mode)
//  - rst_n: Reset assincrono ativo em 0 (BUTTON0)
//  - cargaREM: Habilitacao de carga sincrona (Unidade de Controle)
//  - d[7:0]: Endereco selecionado pelo MUX do REM (vindo do PC ou do RDM)
//  - q[7:0]: Barramento de endereco de 8 bits entregue a memoria ROM/RAM
// ============================================================================
module reg_rem (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       cargaREM,
    input  wire [7:0] d,
    output wire [7:0] q
);
    reg8 u_rem (
        .clk   (clk),
        .rst_n (rst_n),
        .load  (cargaREM),
        .d     (d),
        .q     (q)
    );
endmodule
