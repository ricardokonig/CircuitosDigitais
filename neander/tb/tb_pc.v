`timescale 1ns/1ns

module tb_pc;

    reg        clk;
    reg        rst_n;
    reg        cargaPC;
    reg        incrementaPC;
    reg  [7:0] D;
    wire [7:0] Q;

    integer total = 0;
    integer erros = 0;
    integer i;

    // Instancia do Program Counter (PC)
    pc dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .cargaPC      (cargaPC),
        .incrementaPC (incrementaPC),
        .D            (D),
        .Q            (Q)
    );

    // Gerador de clock (periodo = 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Tarefa para aplicar pulso de clock síncrono
    task clock_pulse;
        begin
            #5;
            clk = 1;
            #5;
            clk = 0;
        end
    endtask

    // Tarefa de verificacao
    task checar(input [7:0] obtido, input [7:0] esperado, input [256*8:1] nome_teste);
        begin
            total = total + 1;
            if (obtido === esperado) begin
                $display("[PASS] %s | Obtido = 0x%02h (%0d)", nome_teste, obtido, obtido);
            end else begin
                erros = erros + 1;
                $display("[FAIL] %s | Obtido = 0x%02h, Esperado = 0x%02h", nome_teste, obtido, esperado);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_pc.vcd");
        $dumpvars(0, tb_pc);

        $display("\n================================================================================");
        $display("  INICIANDO TESTBENCH DO PROGRAM COUNTER (PC) - NEANDER");
        $display("================================================================================");

        // Estado inicial
        clk = 0;
        rst_n = 1;
        cargaPC = 0;
        incrementaPC = 0;
        D = 8'h00;
        #2;

        // ---------------------------------------------------------------------
        // 1. Reset Assincrono
        // ---------------------------------------------------------------------
        $display("\n--- 1. Reset Assincrono ---");
        rst_n = 0;
        #3;
        checar(Q, 8'h00, "PC: Reset assincrono ativo em 0 zera a contagem para 0x00");

        rst_n = 1;
        #2;
        checar(Q, 8'h00, "PC: Apos desativar reset, permanece 0x00");

        // ---------------------------------------------------------------------
        // 2. Retencao de Estado (Hold / Manter)
        // ---------------------------------------------------------------------
        $display("\n--- 2. Retencao de Estado (Hold: cargaPC=0, incPC=0) ---");
        cargaPC = 0;
        incrementaPC = 0;
        D = 8'hAA;
        clock_pulse;
        checar(Q, 8'h00, "PC: Hold ciclo 1");
        clock_pulse;
        checar(Q, 8'h00, "PC: Hold ciclo 2");

        // ---------------------------------------------------------------------
        // 3. Incremento Sequencial (PC = PC + 1)
        // ---------------------------------------------------------------------
        $display("\n--- 3. Incremento Sequencial (0x00 ate 0x0A) ---");
        incrementaPC = 1;
        cargaPC = 0;
        for (i = 1; i <= 10; i = i + 1) begin
            clock_pulse;
            checar(Q, i[7:0], "PC: Incrementando sequencialmente");
        end

        // Parar o incremento e checar se mantem
        incrementaPC = 0;
        clock_pulse;
        checar(Q, 8'h0A, "PC: Hold apos incremento (mantem 0x0A)");

        // ---------------------------------------------------------------------
        // 4. Carga Paralela (Salto / JMP, JN, JZ)
        // ---------------------------------------------------------------------
        $display("\n--- 4. Carga Paralela de Endereco de Salto ---");
        D = 8'h80;
        cargaPC = 1;
        incrementaPC = 0;
        clock_pulse;
        checar(Q, 8'h80, "PC: Carga de salto para 0x80 (JMP 128)");

        // Hold no endereco carregado
        cargaPC = 0;
        D = 8'h00;
        clock_pulse;
        checar(Q, 8'h80, "PC: Retem 0x80 apos carga");

        // Incrementa a partir do salto
        incrementaPC = 1;
        clock_pulse;
        checar(Q, 8'h81, "PC: Incrementa a partir de 0x80 -> 0x81");
        clock_pulse;
        checar(Q, 8'h82, "PC: Incrementa a partir de 0x81 -> 0x82");

        // Outro salto para endereco 0x3F
        incrementaPC = 0;
        cargaPC = 1;
        D = 8'h3F;
        clock_pulse;
        checar(Q, 8'h3F, "PC: Carga de salto para 0x3F");

        cargaPC = 0;
        clock_pulse;
        checar(Q, 8'h3F, "PC: Retem 0x3F");

        // ---------------------------------------------------------------------
        // 5. Prioridade de Carga sobre Incremento
        // ---------------------------------------------------------------------
        $display("\n--- 5. Prioridade de cargaPC sobre incrementaPC ---");
        // Se ambos forem 1 simultaneamente, deve priorizar a carga
        cargaPC = 1;
        incrementaPC = 1;
        D = 8'hC5;
        clock_pulse;
        checar(Q, 8'hC5, "PC: Prioridade para cargaPC (carregou 0xC5 ao inves de incrementar)");

        // ---------------------------------------------------------------------
        // 6. Teste de Overflow de 8 bits (0xFF -> 0x00)
        // ---------------------------------------------------------------------
        $display("\n--- 6. Teste de Overflow (0xFF -> 0x00) ---");
        cargaPC = 1;
        incrementaPC = 0;
        D = 8'hFE;
        clock_pulse;
        checar(Q, 8'hFE, "PC: Carregado com 0xFE");

        cargaPC = 0;
        incrementaPC = 1;
        clock_pulse;
        checar(Q, 8'hFF, "PC: Incrementa 0xFE -> 0xFF");

        clock_pulse;
        checar(Q, 8'h00, "PC: Overflow 0xFF + 1 -> 0x00 (modulo 256)");

        clock_pulse;
        checar(Q, 8'h01, "PC: Continua contagem 0x00 -> 0x01");

        // ---------------------------------------------------------------------
        // 7. Reset Assincrono Durante Operacao
        // ---------------------------------------------------------------------
        $display("\n--- 7. Reset Assincrono Durante Operacao ---");
        cargaPC = 1;
        incrementaPC = 0;
        D = 8'h77;
        clock_pulse;
        checar(Q, 8'h77, "PC: Carregado com 0x77");

        cargaPC = 0;
        // Reset assincrono sem borda de clock
        rst_n = 0;
        #1;
        checar(Q, 8'h00, "PC: Reset assincrono imediato (sem esperar clock) zera para 0x00");

        rst_n = 1;
        #2;
        checar(Q, 8'h00, "PC: Permanece 0x00 apos desativacao do reset");

        // ---------------------------------------------------------------------
        // Resumo dos Resultados
        // ---------------------------------------------------------------------
        $display("\n================================================================================");
        $display("  RESUMO DOS TESTES DO PROGRAM COUNTER (PC):");
        $display("  Total de Verificacoes : %0d", total);
        $display("  Aprovadas             : %0d", total - erros);
        $display("  Falhas                : %0d", erros);
        $display("================================================================================");

        if (erros == 0)
            $display(">>> SUCESSO: Todos os testes do PC passaram com exito! <<<\n");
        else
            $display(">>> FALHA: Detectados erros na execucao dos testes do PC! <<<\n");

        $finish;
    end

endmodule
