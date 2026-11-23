`timescale 1ns/1ns

module tb_divisor;

    // Sinais para div_stage
    reg  clk_in_s;
    reg  rst_n_s;
    wire clk_out_s;

    // Sinais para div_8stages
    reg  clk_in_8;
    reg  rst_n_8;
    wire clk_out_8;

    // Sinais para divisor_clock (Top 24 estagios)
    reg  clk_50MHz;
    reg  rst_n_top;
    wire clk_2Hz;

    integer total = 0;
    integer erros = 0;
    integer i;
    integer posedge_count;

    // Instancias sob teste
    div_stage dut_stage (
        .clk_in  (clk_in_s),
        .rst_n   (rst_n_s),
        .clk_out (clk_out_s)
    );

    div_8stages dut_8stages (
        .clk_in  (clk_in_8),
        .rst_n   (rst_n_8),
        .clk_out (clk_out_8)
    );

    divisor_clock dut_top (
        .clk_50MHz (clk_50MHz),
        .rst_n     (rst_n_top),
        .clk_2Hz   (clk_2Hz)
    );

    task checar_bit;
        input       obtido;
        input       esperado;
        input [80*8:1] nome_teste;
        begin
            total = total + 1;
            if (obtido !== esperado) begin
                $display("  [FALHOU] %0s | Esperado: %b | Obtido: %b", nome_teste, esperado, obtido);
                erros = erros + 1;
            end else begin
                $display("  [PASSOU] %0s -> %b", nome_teste, obtido);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_divisor.vcd");
        $dumpvars(0, tb_divisor);

        $display("================================================================================");
        $display("  INICIO DOS TESTES DO DIVISOR DE CLOCK ESTRUTURAL (ID 5)");
        $display("================================================================================");

        // ---------------------------------------------------------------------
        // 1. Testes do Estagio Basico (div_stage - Divisor por 2)
        // ---------------------------------------------------------------------
        $display("\n--- 1. Testes do Estagio Basico (div_stage: divisao por 2) ---");
        clk_in_s = 0;
        rst_n_s  = 0;
        #10;
        checar_bit(clk_out_s, 1'b0, "div_stage: Reset assincrono ativo mantem saida em 0");

        rst_n_s = 1;
        #10;

        // Pulso 1: posedge clk_in -> clk_out vai para 1
        clk_in_s = 1; #10;
        checar_bit(clk_out_s, 1'b1, "div_stage: 1o pulso (posedge) -> saida toggle para 1");
        clk_in_s = 0; #10;
        checar_bit(clk_out_s, 1'b1, "div_stage: negedge clk_in -> saida mantem 1");

        // Pulso 2: posedge clk_in -> clk_out vai para 0
        clk_in_s = 1; #10;
        checar_bit(clk_out_s, 1'b0, "div_stage: 2o pulso (posedge) -> saida toggle para 0");
        clk_in_s = 0; #10;
        checar_bit(clk_out_s, 1'b0, "div_stage: negedge clk_in -> saida mantem 0");

        // Pulso 3: posedge clk_in -> clk_out vai para 1
        clk_in_s = 1; #10;
        checar_bit(clk_out_s, 1'b1, "div_stage: 3o pulso (posedge) -> saida toggle para 1");

        // Ativa reset durante nivel alto -> deve zerar assincronamente
        rst_n_s = 0; #5;
        checar_bit(clk_out_s, 1'b0, "div_stage: Reset assincrono imediato com clock em 1");
        rst_n_s = 1; clk_in_s = 0; #10;

        // ---------------------------------------------------------------------
        // 2. Testes do Bloco de 8 Estagios (div_8stages - Divisor por 256)
        // ---------------------------------------------------------------------
        $display("\n--- 2. Testes do Bloco de 8 Estagios (div_8stages: divisao por 256) ---");
        clk_in_8 = 0;
        rst_n_8  = 0;
        #20;
        checar_bit(clk_out_8, 1'b0, "div_8stages: Reset assincrono zera todos os 8 estagios");

        rst_n_8 = 1;
        #10;

        posedge_count = 0;

        // Injeta 512 pulsos de clock (exatamente 2 ciclos completos de saida)
        for (i = 1; i <= 512; i = i + 1) begin
            clk_in_8 = 1; #5;

            // No pulso 128 (meio ciclo do divisor por 256), a saida deve ir para 1
            if (i == 128) begin
                checar_bit(clk_out_8, 1'b1, "div_8stages: No 128o ciclo -> clk_out transiciona para 1");
            end
            // No pulso 256 (1 ciclo completo do divisor), a saida deve voltar para 0
            if (i == 256) begin
                checar_bit(clk_out_8, 1'b0, "div_8stages: No 256o ciclo -> clk_out completa 1 periodo (volta a 0)");
            end
            // No pulso 384, a saida transiciona novamente para 1
            if (i == 384) begin
                checar_bit(clk_out_8, 1'b1, "div_8stages: No 384o ciclo -> clk_out transiciona para 1");
            end
            // No pulso 512, a saida completa o 2o periodo
            if (i == 512) begin
                checar_bit(clk_out_8, 1'b0, "div_8stages: No 512o ciclo -> clk_out completa 2 periodos");
            end

            clk_in_8 = 0; #5;
        end

        // ---------------------------------------------------------------------
        // 3. Testes do Top-Level (divisor_clock - 24 estagios)
        // ---------------------------------------------------------------------
        $display("\n--- 3. Testes do Top-Level (divisor_clock: 24 estagios / cascata de 3 blocos) ---");
        clk_50MHz = 0;
        rst_n_top = 0;
        #20;
        checar_bit(clk_2Hz, 1'b0, "divisor_clock: Reset assincrono zera saida final clk_2Hz");
        checar_bit(dut_top.clk_div8, 1'b0, "divisor_clock: Reset assincrono zera estagio intermediario clk_div8");
        checar_bit(dut_top.clk_div16, 1'b0, "divisor_clock: Reset assincrono zera estagio intermediario clk_div16");

        rst_n_top = 1;
        #10;

        // Injeta 512 pulsos de 50 MHz e verifica se o primeiro bloco (b1) opera
        for (i = 1; i <= 512; i = i + 1) begin
            clk_50MHz = 1; #5;
            clk_50MHz = 0; #5;
        end
        checar_bit(dut_top.clk_div8, 1'b0, "divisor_clock: b1 completou 2 periodos de clk_div8 apos 512 pulsos");

        // Injeta mais 256 pulsos para deixar clk_div8 em nivel alto (1)
        for (i = 1; i <= 128; i = i + 1) begin
            clk_50MHz = 1; #5;
            clk_50MHz = 0; #5;
        end
        checar_bit(dut_top.clk_div8, 1'b1, "divisor_clock: b1 esta em nivel alto (1) no 128o pulso do 3o periodo");

        // Testa reset global assincrono durante execucao
        rst_n_top = 0;
        #5;
        checar_bit(dut_top.clk_div8, 1'b0, "divisor_clock: Reset assincrono zera b1 imediatamente");
        checar_bit(clk_2Hz, 1'b0, "divisor_clock: Saida final permanece em 0 sob reset");

        // ---------------------------------------------------------------------
        // Resumo dos Resultados
        // ---------------------------------------------------------------------
        $display("\n================================================================================");
        $display("  RESUMO DOS TESTES DO DIVISOR DE CLOCK:");
        $display("  Total de Verificacoes : %0d", total);
        $display("  Aprovadas             : %0d", total - erros);
        $display("  Falhas                : %0d", erros);
        $display("================================================================================");

        if (erros == 0)
            $display(">>> SUCESSO: Todos os testes do Divisor de Clock passaram com exito! <<<\n");
        else
            $display(">>> FALHA: Detectados erros na execucao dos testes do Divisor de Clock! <<<\n");

        $finish;
    end

endmodule
