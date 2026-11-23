`timescale 1ns/1ns

module tb_neander;

    reg        clk_50MHz;
    reg        rst_n;
    reg        btn_step_n;
    reg        modo_run;

    wire       led_n;
    wire       led_z;
    wire       led_hlt;

    wire [6:0] hex0;
    wire [6:0] hex1;
    wire [6:0] hex2;
    wire [6:0] hex3;

    integer total_tests = 0;
    integer passed_tests = 0;
    integer cycle_count = 0;

    // Instancia o Neander com SIMULATION=1 para usar clk_50MHz diretamente
    neander_top #(.SIMULATION(1)) dut (
        .clk_50MHz  (clk_50MHz),
        .rst_n      (rst_n),
        .btn_step_n (btn_step_n),
        .modo_run   (modo_run),
        .led_n      (led_n),
        .led_z      (led_z),
        .led_hlt    (led_hlt),
        .hex0       (hex0),
        .hex1       (hex1),
        .hex2       (hex2),
        .hex3       (hex3)
    );

    // Clock de simulacao: periodo de 10ns (50 MHz equivalente na simulacao)
    always #5 clk_50MHz = ~clk_50MHz;

    task checar_valor;
        input [7:0] val_obtido;
        input [7:0] val_esperado;
        input [8*60:1] nome;
        begin
            total_tests = total_tests + 1;
            if (val_obtido === val_esperado) begin
                passed_tests = passed_tests + 1;
                $display("  [PASSOU] %0s = 0x%02X", nome, val_obtido);
            end else begin
                $display("  [FALHOU] %0s = 0x%02X (esperado: 0x%02X)", nome, val_obtido, val_esperado);
            end
        end
    endtask

    task checar_bit;
        input bit_obtido;
        input bit_esperado;
        input [8*60:1] nome;
        begin
            total_tests = total_tests + 1;
            if (bit_obtido === bit_esperado) begin
                passed_tests = passed_tests + 1;
                $display("  [PASSOU] %0s = %b", nome, bit_obtido);
            end else begin
                $display("  [FALHOU] %0s = %b (esperado: %b)", nome, bit_obtido, bit_esperado);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_neander.vcd");
        $dumpvars(0, tb_neander);

        $display("================================================================================");
        $display("  INICIO DA SIMULACAO COMPLETA: PROCESSADOR NEANDER TOP-LEVEL");
        $display("================================================================================");

        // Inicializacao dos sinais
        clk_50MHz  = 0;
        rst_n      = 0;
        btn_step_n = 1;
        modo_run   = 1; // Inicia em modo continuo
        #25;

        // 1. Verificacao durante Reset Assincrono
        checar_valor(dut.pc_out, 8'h00, "1.1 PC zerado no reset");
        checar_valor(dut.ac_out, 8'h00, "1.2 AC zerado no reset");
        checar_bit(led_n, 0, "1.3 Flag N zerado no reset");
        checar_bit(led_z, 0, "1.4 Flag Z zerado no reset");
        checar_bit(led_hlt, 0, "1.5 LED HLT desativado no reset");

        // Libera o reset
        rst_n = 1;
        #10;

        $display("\n--- Executando Programa Neander Completo na Memoria ---");

        // Deixa a CPU rodar ate encontrar o sinal de HLT (ou limite de seguranca de 500 ciclos)
        while (!led_hlt && cycle_count < 500) begin
            @(posedge clk_50MHz);
            cycle_count = cycle_count + 1;
        end

        #20; // Margem para estabilizacao pos-HLT

        $display(">>> CPU atingiu estado de PARADA (HLT) apos %0d ciclos de clock! <<<\n", cycle_count);

        // 2. Verificacao do estado final pos-HLT:
        //  - AC deve conter 0xAA (resultado final apos LDA, ADD, STA, NOT, JN, AND, JZ, OR)
        //  - Memoria em 0x82 deve conter 0x08 (resultado de 5 + 3 gravado pelo STA)
        //  - Flag N deve ser 1 (0xAA possui bit 7 = 1)
        //  - Flag Z deve ser 0 (0xAA != 0)
        //  - LED HLT deve estar aceso (1)
        checar_bit(led_hlt, 1, "2.1 LED HLT aceso (instrucao HLT decodificada)");
        checar_valor(dut.ac_out, 8'hAA, "2.2 AC final correto (0xAA)");
        checar_valor(dut.u_mem.mem[8'h82], 8'h08, "2.3 Memoria[0x82] gravada com sucesso pelo STA (5 + 3 = 8)");
        checar_bit(led_n, 1, "2.4 Flag N ativo (0xAA eh negativo em complemento de 2)");
        checar_bit(led_z, 0, "2.5 Flag Z inativo (0xAA != 0)");

        // 3. Verificacao dos Displays de 7 Segmentos:
        //  - AC = 0xAA -> hex1 = 7'b0001000 ('A'), hex0 = 7'b0001000 ('A')
        total_tests = total_tests + 1;
        if (hex1 === 7'b0001000 && hex0 === 7'b0001000) begin
            passed_tests = passed_tests + 1;
            $display("  [PASSOU] 3.1 Displays do AC (HEX1, HEX0) exibem 'AA' corretamente");
        end else begin
            $display("  [FALHOU] 3.1 Displays do AC: HEX1=%b HEX0=%b (esperado: 0001000)", hex1, hex0);
        end

        // 4. Teste de Congelamento: com HLT ativo, mais ciclos de clock nao devem alterar AC nem PC
        @(posedge clk_50MHz); #1;
        checar_valor(dut.ac_out, 8'hAA, "4.1 AC permanece congelado sob HLT");
        checar_bit(led_hlt, 1, "4.2 HLT permanece estavel");

        // 5. Teste do Modo STEP (modo_run = 0 e pulsos manuais via btn_step_n)
        $display("\n--- Testando Modo STEP com Reset e Avanco Manual ---");
        rst_n = 0; #20; rst_n = 1; #10;
        modo_run = 0; // Entra em modo STEP

        // Da 4 passos manuais com BUTTON1 (pulsando btn_step_n de 1 -> 0 -> 1)
        // Cada pulso gera uma borda de subida no clock do Neander
        btn_step_n = 0; #10; btn_step_n = 1; #20; // Passo 1 (t0)
        btn_step_n = 0; #10; btn_step_n = 1; #20; // Passo 2 (t1)
        btn_step_n = 0; #10; btn_step_n = 1; #20; // Passo 3 (t2)
        btn_step_n = 0; #10; btn_step_n = 1; #20; // Passo 4 (t3)

        checar_valor(dut.pc_out, 8'h01, "5.1 PC incrementou para 0x01 no modo STEP apos fetch");

        $display("================================================================================");
        $display("  RESUMO DOS TESTES DO NEANDER TOP-LEVEL:");
        $display("  Total de Verificacoes : %0d", total_tests);
        $display("  Aprovadas             : %0d", passed_tests);
        $display("  Falhas                : %0d", total_tests - passed_tests);
        $display("================================================================================");

        if (passed_tests == total_tests) begin
            $display(">>> SUCESSO ABSOLUTO: PROCESSADOR NEANDER VALIDADO DE PONTA A PONTA! <<<\n");
        end else begin
            $display(">>> FALHA: Ocorreram erros na simulacao do Neander! <<<\n");
        end

        $finish;
    end

endmodule
