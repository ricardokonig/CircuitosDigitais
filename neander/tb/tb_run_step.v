`timescale 1ns/1ns

module tb_run_step;

    reg  clk_auto;
    reg  btn_step_n;
    reg  modo_run;
    wire clk_out;

    integer total = 0;
    integer erros = 0;

    // Instancia do Run/Step Mode sob teste
    run_step_mode dut (
        .clk_auto   (clk_auto),
        .btn_step_n (btn_step_n),
        .modo_run   (modo_run),
        .clk_out    (clk_out)
    );

    task checar_clk;
        input       esperado;
        input [80*8:1] nome_teste;
        begin
            total = total + 1;
            #2; // Aguarda propagacao das portas estruturais
            if (clk_out !== esperado) begin
                $display("  [FALHOU] %0s | modo=%b, clk_auto=%b, btn_n=%b | Esperado: %b | Obtido: %b",
                         nome_teste, modo_run, clk_auto, btn_step_n, esperado, clk_out);
                erros = erros + 1;
            end else begin
                $display("  [PASSOU] %0s -> clk_out=%b", nome_teste, clk_out);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_run_step.vcd");
        $dumpvars(0, tb_run_step);

        $display("================================================================================");
        $display("  INICIO DOS TESTES DO RUN/STEP MODE (ID 6)");
        $display("================================================================================");

        // ---------------------------------------------------------------------
        // 1. Testes no Modo RUN (modo_run = 1: clock continuo)
        // ---------------------------------------------------------------------
        $display("\n--- 1. Testes no Modo RUN (SW0 = 1: Opera com clk_auto) ---");
        modo_run   = 1'b1;
        btn_step_n = 1'b1; // Botao solto
        clk_auto   = 1'b0;
        checar_clk(1'b0, "Modo RUN: clk_auto=0 -> clk_out=0");

        clk_auto   = 1'b1;
        checar_clk(1'b1, "Modo RUN: clk_auto=1 -> clk_out=1");

        clk_auto   = 1'b0;
        checar_clk(1'b0, "Modo RUN: clk_auto volta para 0 -> clk_out=0");

        // Pressionar o botao no modo RUN nao deve interferir no clock continuo
        $display("\n--- 1.1 Verificando imunidade a pulsos de botao no Modo RUN ---");
        btn_step_n = 1'b0; // Pressiona botao
        clk_auto   = 1'b1;
        checar_clk(1'b1, "Modo RUN com botao pressionado: clk_auto=1 mantem clk_out=1");

        clk_auto   = 1'b0;
        checar_clk(1'b0, "Modo RUN com botao pressionado: clk_auto=0 mantem clk_out=0");

        btn_step_n = 1'b1; // Solta botao
        #5;

        // ---------------------------------------------------------------------
        // 2. Testes no Modo STEP / DEBUG (modo_run = 0: avanco manual)
        // ---------------------------------------------------------------------
        $display("\n--- 2. Testes no Modo STEP (SW0 = 0: Avanco manual via BUTTON1) ---");
        modo_run   = 1'b0;
        clk_auto   = 1'b0;
        btn_step_n = 1'b1; // Botao solto (nivel 1 na DE0)
        checar_clk(1'b0, "Modo STEP: Botao solto (btn_n=1) -> clk_out=0 (repouso)");

        // Simulando aperto do botao BUTTON1: vai para 0 -> gera borda de subida no clock
        btn_step_n = 1'b0;
        checar_clk(1'b1, "Modo STEP: Botao pressionado (btn_n=0) -> borda de subida (clk_out=1)");

        // Soltando o botao: volta a 0
        btn_step_n = 1'b1;
        checar_clk(1'b0, "Modo STEP: Botao liberado (btn_n=1) -> clk_out volta a 0");

        // Segundo ciclo de passo
        btn_step_n = 1'b0;
        checar_clk(1'b1, "Modo STEP: 2o passo (btn_n=0) -> clk_out=1");

        btn_step_n = 1'b1;
        checar_clk(1'b0, "Modo STEP: 2o passo liberado -> clk_out=0");

        // Verificar imunidade ao clk_auto no modo STEP
        $display("\n--- 2.1 Verificando imunidade ao clk_auto no Modo STEP ---");
        clk_auto = 1'b1;
        checar_clk(1'b0, "Modo STEP: clk_auto oscila para 1, mas clk_out permanece em 0");

        clk_auto = 1'b0;
        checar_clk(1'b0, "Modo STEP: clk_auto oscila para 0, clk_out permanece em 0");

        // ---------------------------------------------------------------------
        // 3. Comutacao Dinamica de Modo
        // ---------------------------------------------------------------------
        $display("\n--- 3. Teste de Comutacao Dinamica entre Modos ---");
        clk_auto   = 1'b1;
        btn_step_n = 1'b1;
        modo_run   = 1'b1; // RUN
        checar_clk(1'b1, "Comutacao: em RUN com clk_auto=1 -> clk_out=1");

        modo_run   = 1'b0; // Muda para STEP sem mexer no botao
        checar_clk(1'b0, "Comutacao para STEP: clk_out desce para 0 (ignora clk_auto)");

        modo_run   = 1'b1; // Volta para RUN
        checar_clk(1'b1, "Retorno para RUN: clk_out volta a seguir clk_auto=1");

        // ---------------------------------------------------------------------
        // Resumo dos Resultados
        // ---------------------------------------------------------------------
        $display("\n================================================================================");
        $display("  RESUMO DOS TESTES DO RUN/STEP MODE:");
        $display("  Total de Verificacoes : %0d", total);
        $display("  Aprovadas             : %0d", total - erros);
        $display("  Falhas                : %0d", erros);
        $display("================================================================================");

        if (erros == 0)
            $display(">>> SUCESSO: Todos os testes do Run/Step Mode passaram com exito! <<<\n");
        else
            $display(">>> FALHA: Detectados erros na execucao dos testes do Run/Step Mode! <<<\n");

        $finish;
    end

endmodule
