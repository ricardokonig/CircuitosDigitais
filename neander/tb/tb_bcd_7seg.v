`timescale 1ns/1ns

module tb_bcd_7seg;

    reg  [3:0] in;
    wire [6:0] seg;

    integer i;
    integer total_tests = 0;
    integer passed_tests = 0;

    // Tabela esperada de segmentos (g f e d c b a) em nivel baixo:
    // 0: 7'b1000000 (0x40)
    // 1: 7'b1111001 (0x79)
    // 2: 7'b0100100 (0x24)
    // 3: 7'b0110000 (0x30)
    // 4: 7'b0011001 (0x19)
    // 5: 7'b0010010 (0x12)
    // 6: 7'b0000010 (0x02)
    // 7: 7'b1111000 (0x78)
    // 8: 7'b0000000 (0x00)
    // 9: 7'b0010000 (0x10)
    // A: 7'b0001000 (0x08)
    // B: 7'b0000011 (0x03)
    // C: 7'b1000110 (0x46)
    // D: 7'b0100001 (0x21)
    // E: 7'b0000110 (0x06)
    // F: 7'b0001110 (0x0E)
    reg [6:0] esperado [0:15];

    bcd_7seg dut (
        .in  (in),
        .seg (seg)
    );

    initial begin
        $dumpfile("tb_bcd_7seg.vcd");
        $dumpvars(0, tb_bcd_7seg);

        esperado[4'h0] = 7'b1000000;
        esperado[4'h1] = 7'b1111001;
        esperado[4'h2] = 7'b0100100;
        esperado[4'h3] = 7'b0110000;
        esperado[4'h4] = 7'b0011001;
        esperado[4'h5] = 7'b0010010;
        esperado[4'h6] = 7'b0000010;
        esperado[4'h7] = 7'b1111000;
        esperado[4'h8] = 7'b0000000;
        esperado[4'h9] = 7'b0010000;
        esperado[4'hA] = 7'b0001000;
        esperado[4'hB] = 7'b0000011;
        esperado[4'hC] = 7'b1000110;
        esperado[4'hD] = 7'b0100001;
        esperado[4'hE] = 7'b0000110;
        esperado[4'hF] = 7'b0001110;

        $display("================================================================================");
        $display("  INICIO DOS TESTES DO DECODIFICADOR BCD/HEX 7 SEGMENTOS ESTRUTURAL (ID 12)");
        $display("================================================================================");

        for (i = 0; i < 16; i = i + 1) begin
            in = i;
            #10;
            total_tests = total_tests + 1;
            if (seg === esperado[i]) begin
                passed_tests = passed_tests + 1;
                $display("  [PASSOU] Entrada = 0x%X -> seg = %b (esperado: %b)", i, seg, esperado[i]);
            end else begin
                $display("  [FALHOU] Entrada = 0x%X -> seg = %b (esperado: %b)", i, seg, esperado[i]);
            end
        end

        $display("================================================================================");
        $display("  RESUMO DOS TESTES DO DECODIFICADOR 7 SEGMENTOS:");
        $display("  Total de Verificacoes : %0d", total_tests);
        $display("  Aprovadas             : %0d", passed_tests);
        $display("  Falhas                : %0d", total_tests - passed_tests);
        $display("================================================================================");

        if (passed_tests == total_tests) begin
            $display(">>> SUCESSO: Todos os testes do Decodificador 7 Segmentos passaram com exito! <<<\n");
        end else begin
            $display(">>> FALHA: Houve erros no teste do Decodificador 7 Segmentos! <<<\n");
        end

        $finish;
    end

endmodule
