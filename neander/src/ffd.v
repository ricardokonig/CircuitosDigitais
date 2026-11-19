`timescale 1ns/1ns

// flip-flop D basico com reset assincrono ativo em 0
module ffd (
    input  wire clk,
    input  wire rst_n, // reset em 0 zera a saida
    input  wire d,
    output reg  q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule
