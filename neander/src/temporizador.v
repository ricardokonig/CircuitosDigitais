`timescale 1ns/1ns

// anel de 8 bits (one-hot): gera os passos de tempo t0 ate t7
module temporizador (
    input  wire clk,
    input  wire rst_n,
    input  wire goto_t0, // forca voltar pro t0
    input  wire hlt,     // congela tudo se der halt
    output wire t0, t1, t2, t3, t4, t5, t6, t7
);
    wire d0, d1, d2, d3, d4, d5, d6, d7;
    wire [7:0] q;

    // se hlt estiver ativo, nao avanca
    wire not_hlt;
    not #1 g_nhlt (not_hlt, hlt);

    // volta pro t0 se der goto_t0 ou se o anel deu a volta (veio de t7)
    wire or_d0;
    or  #1 g_ord0 (or_d0, goto_t0, q[7]);
    and #1 g_and0 (d0, not_hlt, or_d0);

    // habilita passar a bola pro proximo estagio (t1..t7)
    wire not_goto;
    not #1 g_ngoto (not_goto, goto_t0);

    wire en_shift;
    and #1 g_enshift (en_shift, not_hlt, not_goto);

    // logica de deslocamento do pulso: passa o bit 1 pro proximo flip-flop
    and #1 g_d1 (d1, en_shift, q[0]);
    and #1 g_d2 (d2, en_shift, q[1]);
    and #1 g_d3 (d3, en_shift, q[2]);
    and #1 g_d4 (d4, en_shift, q[3]);
    and #1 g_d5 (d5, en_shift, q[4]);
    and #1 g_d6 (d6, en_shift, q[5]);
    and #1 g_d7 (d7, en_shift, q[6]);

    // estagio t0: precisa iniciar em 1 no reset pro Neander comecar no passo t0
    reg reg_t0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reg_t0 <= 1'b1;
        else if (hlt)
            reg_t0 <= reg_t0;
        else
            reg_t0 <= d0;
    end
    assign q[0] = reg_t0;

    // estagios t1 ate t7: iniciam zerados no reset
    ffd ff1 (.clk(clk), .rst_n(rst_n), .d(hlt ? q[1] : d1), .q(q[1]));
    ffd ff2 (.clk(clk), .rst_n(rst_n), .d(hlt ? q[2] : d2), .q(q[2]));
    ffd ff3 (.clk(clk), .rst_n(rst_n), .d(hlt ? q[3] : d3), .q(q[3]));
    ffd ff4 (.clk(clk), .rst_n(rst_n), .d(hlt ? q[4] : d4), .q(q[4]));
    ffd ff5 (.clk(clk), .rst_n(rst_n), .d(hlt ? q[5] : d5), .q(q[5]));
    ffd ff6 (.clk(clk), .rst_n(rst_n), .d(hlt ? q[6] : d6), .q(q[6]));
    ffd ff7 (.clk(clk), .rst_n(rst_n), .d(hlt ? q[7] : d7), .q(q[7]));

    // liga as saidas do temporizador
    assign t0 = q[0];
    assign t1 = q[1];
    assign t2 = q[2];
    assign t3 = q[3];
    assign t4 = q[4];
    assign t5 = q[5];
    assign t6 = q[6];
    assign t7 = q[7];

endmodule
