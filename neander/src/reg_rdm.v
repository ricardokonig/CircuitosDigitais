`timescale 1ns/1ns

// ============================================================================
// Registrador de Dados da Memoria (RDM) - Processador Neander
// ============================================================================
// Registrador de 8 bits que faz interface de dados com a memoria (RAM/ROM).
//
// Conexoes no Neander:
//  - clk: Clock efetivo do sistema (Run/Step Mode)
//  - rst_n: Reset assincrono ativo em 0 (BUTTON0)
//  - cargaRDM: Habilitacao de carga sincrona (Unidade de Controle)
//  - d[7:0]: Barramento de entrada de dados (vindo da memoria em leitura,
//            ou do AC na instrucao STA em t6)
//  - q[7:0]: Saida conectada a entrada Y da ULA, ao MUX do REM, ao PC (desvios),
//            ao RI (fetch) e ao barramento de escrita da memoria
// ============================================================================
module reg_rdm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       cargaRDM,
    input  wire [7:0] d,
    output wire [7:0] q
);
    reg8 u_rdm (
        .clk   (clk),
        .rst_n (rst_n),
        .load  (cargaRDM),
        .d     (d),
        .q     (q)
    );
endmodule
