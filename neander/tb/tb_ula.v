`timescale 1ns/1ns

module tb_ula;

    reg  [7:0] x;
    reg  [7:0] y;
    reg  [2:0] selUAL;
    wire [7:0] s;
    wire       flag_n;
    wire       flag_z;

    integer erros = 0;
    integer total = 0;

    // Instancia da ULA sob teste
    ula dut (
        .x(x),
        .y(y),
        .selUAL(selUAL),
        .s(s),
        .flag_n(flag_n),
        .flag_z(flag_z)
    );

    // Tarefa auxiliar para verificacao com atraso para propagacao das portas
    task checar;
        input [7:0] exp_s;
        input       exp_n;
        input       exp_z;
        input [80*8:1] nome_teste;
        begin
            total = total + 1;
            #25; // Aguarda estabilizacao do ripple carry e portas logicas
            if (s !== exp_s || flag_n !== exp_n || flag_z !== exp_z) begin
                $display("  [FALHOU] %0s | Esperado: s=%h (n=%b, z=%b) | Obtido: s=%h (n=%b, z=%b)",
                         nome_teste, exp_s, exp_n, exp_z, s, flag_n, flag_z);
                erros = erros + 1;
            end else begin
                $display("  [PASSOU] %0s -> s=%h, N=%b, Z=%b", nome_teste, s, flag_n, flag_z);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_ula.vcd");
        $dumpvars(0, tb_ula);

        $display("================================================================================");
        $display("  INICIO DOS TESTES DA ULA DO NEANDER");
        $display("================================================================================");

        // ---------------------------------------------------------------------
        // 1. Operacao Y (selUAL = 3'b000) - Instrucao LDA
        // ---------------------------------------------------------------------
        $display("\n--- 1. Testes da Operacao Passa Y (selUAL = 000) ---");
        x = 8'hAA; y = 8'h55; selUAL = 3'b000;
        checar(8'h55, 0, 0, "Passa Y positivo (0x55)");

        x = 8'h00; y = 8'h80; selUAL = 3'b000;
        checar(8'h80, 1, 0, "Passa Y negativo (0x80)");

        x = 8'hFF; y = 8'h00; selUAL = 3'b000;
        checar(8'h00, 0, 1, "Passa Y zero (0x00)");

        // ---------------------------------------------------------------------
        // 2. Operacao ADD (selUAL = 3'b001) - Instrucao ADD
        // ---------------------------------------------------------------------
        $display("\n--- 2. Testes da Operacao ADD (selUAL = 001) ---");
        x = 8'd25; y = 8'd35; selUAL = 3'b001;
        checar(8'd60, 0, 0, "ADD normal (25 + 35 = 60)");

        x = 8'h7F; y = 8'h01; selUAL = 3'b001;
        checar(8'h80, 1, 0, "ADD com resultado negativo (127 + 1 = -128 / 0x80)");

        x = 8'hFF; y = 8'h01; selUAL = 3'b001;
        checar(8'h00, 0, 1, "ADD com overflow para zero (255 + 1 = 0)");

        x = 8'hFE; y = 8'h02; selUAL = 3'b001;
        checar(8'h00, 0, 1, "ADD resultando em zero (254 + 2 = 0)");

        // ---------------------------------------------------------------------
        // 3. Operacao AND (selUAL = 3'b010) - Instrucao AND
        // ---------------------------------------------------------------------
        $display("\n--- 3. Testes da Operacao AND (selUAL = 010) ---");
        x = 8'b1111_0000; y = 8'b1010_1010; selUAL = 3'b010;
        checar(8'b1010_0000, 1, 0, "AND com bit 7 em 1 (N=1)");

        x = 8'b0101_0101; y = 8'b1010_1010; selUAL = 3'b010;
        checar(8'b0000_0000, 0, 1, "AND resultando em zero (Z=1)");

        // ---------------------------------------------------------------------
        // 4. Operacao OR (selUAL = 3'b011) - Instrucao OR
        // ---------------------------------------------------------------------
        $display("\n--- 4. Testes da Operacao OR (selUAL = 011) ---");
        x = 8'b0000_1111; y = 8'b0111_0000; selUAL = 3'b011;
        checar(8'b0111_1111, 0, 0, "OR positivo (0x7F)");

        x = 8'b1000_0000; y = 8'b0000_0001; selUAL = 3'b011;
        checar(8'b1000_0001, 1, 0, "OR negativo (0x81)");

        x = 8'b0000_0000; y = 8'b0000_0000; selUAL = 3'b011;
        checar(8'b0000_0000, 0, 1, "OR zero (0x00)");

        // ---------------------------------------------------------------------
        // 5. Operacao NOT (selUAL = 3'b100) - Instrucao NOT
        // ---------------------------------------------------------------------
        $display("\n--- 5. Testes da Operacao NOT (selUAL = 100) ---");
        x = 8'h0F; y = 8'hAA; selUAL = 3'b100;
        checar(8'hF0, 1, 0, "NOT invertendo 0x0F para 0xF0 (N=1)");

        x = 8'hFF; y = 8'hAA; selUAL = 3'b100;
        checar(8'h00, 0, 1, "NOT invertendo 0xFF para 0x00 (Z=1)");

        x = 8'h80; y = 8'h00; selUAL = 3'b100;
        checar(8'h7F, 0, 0, "NOT invertendo 0x80 para 0x7F (positivo)");

        // ---------------------------------------------------------------------
        // Relatorio Final
        // ---------------------------------------------------------------------
        $display("\n================================================================================");
        $display("  Total de testes : %0d", total);
        $display("  Passaram        : %0d", total - erros);
        $display("  Falharam        : %0d", erros);
        if (erros == 0) begin
            $display("  >>> SUCESSO: TODOS OS TESTES DA ULA PASSARAM! <<<");
        end else begin
            $display("  >>> ERRO: VERIFIQUE AS FALHAS ACIMA! <<<");
        end
        $display("================================================================================\n");

        $finish;
    end

endmodule
