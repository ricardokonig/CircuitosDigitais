`timescale 1ns/1ns

// ULA combinacional comportamental do Neander (8 bits)
module ula (
    input  wire [7:0] x,       // Operando vindo do AC
    input  wire [7:0] y,       // Operando vindo do RDM / memoria
    input  wire [2:0] selUAL,  // Seletor de operacao (gerado pelo codificador_ula)
    output reg  [7:0] s,       // Resultado da ULA
    output wire       flag_n,  // Flag Negativo
    output wire       flag_z   // Flag Zero
);

    // 1. Logica combinacional das operacoes da ULA
    always @(*) begin
        case (selUAL)
            3'b000:  s = y;        // Passa Y (instrucao LDA)
            3'b001:  s = x + y;    // ADD
            3'b010:  s = x & y;    // AND
            3'b011:  s = x | y;    // OR
            3'b100:  s = ~x;       // NOT (inversao do AC)
            default: s = 8'h00;
        endcase
    end

    // 2. Geracao combinacional das flags de condicao
    assign flag_n = s[7];          // MSB indica sinal negativo em complemento a 2
    assign flag_z = (s == 8'h00);  // 1 se o resultado for identicamente zero (~|s)

endmodule
