`timescale 1ns/1ns

// ============================================================================
// ID 6: Run/Step Mode (Seletor de Modo de Execucao do Neander)
// ============================================================================
// Funcao:
//  - Alterna a fonte do clock do Neander entre:
//      * Modo RUN  (modo_run = 1): Clock continuo gerado pelo divisor (~2 Hz).
//      * Modo STEP (modo_run = 0): Avanco manual por borda do botao BUTTON1.
//
// Mapeamento FPGA Altera DE0:
//  - modo_run: Chave SW0 (1 = Continuo / RUN, 0 = Passo a passo / DEBUG)
//  - btn_step_n: Botao BUTTON1 (ativo em 0, pull-up interno)
//  - clk_auto: Saida clk_2Hz do divisor_clock
//  - clk_out: Clock efetivo entregue a Unidade de Controle e Datapath
// ============================================================================
module run_step_mode (
    input  wire clk_auto,    // Clock lento automatico (~2 Hz do divisor)
    input  wire btn_step_n,  // Botao manual BUTTON1 (ativo em 0: 1=solto, 0=pressionado)
    input  wire modo_run,    // Chave SW0 (1 = RUN, 0 = STEP/DEBUG)
    output wire clk_out      // Clock efetivo para o processador
);

    // 1. Inverte o sinal do botao ativo em nivel baixo (BUTTON1 da DE0):
    //    - Solto (1) -> step_clk = 0
    //    - Pressionado (0) -> step_clk = 1 (gera borda de subida para avanco de passo)
    wire step_clk;
    not u_inv_btn (step_clk, btn_step_n);

    // 2. Multiplexador 2:1 estrutural para selecao de clock:
    //    clk_out = (modo_run & clk_auto) | (~modo_run & step_clk)
    wire not_modo;
    not u_inv_modo (not_modo, modo_run);

    wire w_run, w_step;
    and u_and_run  (w_run,  modo_run, clk_auto);
    and u_and_step (w_step, not_modo, step_clk);
    or  u_or_out   (clk_out, w_run,   w_step);

endmodule
