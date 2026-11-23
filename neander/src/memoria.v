`timescale 1ns/1ns

module memoria #(
    parameter MEM_FILE = "neander_prog.hex"
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       read,
    input  wire       write,
    input  wire [7:0] addr,
    input  wire [7:0] data_in,
    output wire [7:0] data_out
);

    reg [7:0] mem [0:255];

    // Carrega a memoria do arquivo uma unica vez, no inicio da simulacao
    initial begin
        $readmemh(MEM_FILE, mem);
    end

    // Escrita sincrona
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ;                       // reset nao mexe na memoria
        else if (write)
            mem[addr] <= data_in;
    end

    // Leitura combinacional
    assign data_out = (read) ? mem[addr] : 8'h00;

endmodule
