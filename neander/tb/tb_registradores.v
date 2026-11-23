`timescale 1ns/1ns

module tb_registradores;

    // Sinais compartilhados de clock e reset
    reg        clk;
    reg        rst_n;

    // Sinais para o reg8 generico
    reg        load_gen;
    reg  [7:0] d_gen;
    wire [7:0] q_gen;

    // Sinais para AC
    reg        cargaAC;
    reg  [7:0] d_ac;
    wire [7:0] q_ac;

    // Sinais para RDM
    reg        cargaRDM;
    reg  [7:0] d_rdm;
    wire [7:0] q_rdm;

    // Sinais para REM
    reg        cargaREM;
    reg  [7:0] d_rem;
    wire [7:0] q_rem;

    // Sinais para RI
    reg        cargaRI;
    reg  [7:0] d_ri;
    wire [7:0] q_ri;

    integer total = 0;
    integer erros = 0;
    integer i;

    // Instancia do Registrador Generico de 8 bits
    reg8 dut_reg8 (
        .clk   (clk),
        .rst_n (rst_n),
        .load  (load_gen),
        .d     (d_gen),
        .q     (q_gen)
    );

    // Instancia do Acumulador (AC)
    reg_ac dut_ac (
        .clk     (clk),
        .rst_n   (rst_n),
        .cargaAC (cargaAC),
        .d       (d_ac),
        .q       (q_ac)
    );

    // Instancia do Registrador de Dados da Memoria (RDM)
    reg_rdm dut_rdm (
        .clk      (clk),
        .rst_n    (rst_n),
        .cargaRDM (cargaRDM),
        .d        (d_rdm),
        .q        (q_rdm)
    );

    // Instancia do Registrador de Endereco da Memoria (REM)
    reg_rem dut_rem (
        .clk      (clk),
        .rst_n    (rst_n),
        .cargaREM (cargaREM),
        .d        (d_rem),
        .q        (q_rem)
    );

    // Instancia do Registrador de Instrucao (RI)
    reg_ri dut_ri (
        .clk     (clk),
        .rst_n   (rst_n),
        .cargaRI (cargaRI),
        .d       (d_ri),
        .q       (q_ri)
    );

    // Tarefa de checagem generica de 8 bits
    task checar;
        input [7:0] obtido;
        input [7:0] esperado;
        input [80*8:1] nome_teste;
        begin
            total = total + 1;
            if (obtido !== esperado) begin
                $display("  [FALHOU] %0s | Esperado: %h | Obtido: %h", nome_teste, esperado, obtido);
                erros = erros + 1;
            end else begin
                $display("  [PASSOU] %0s -> %h", nome_teste, obtido);
            end
        end
    endtask

    // Tarefa para pulsar o clock
    task clock_pulse;
        begin
            #5; clk = 1; #5; clk = 0; #2;
        end
    endtask

    initial begin
        $dumpfile("tb_registradores.vcd");
        $dumpvars(0, tb_registradores);

        $display("================================================================================");
        $display("  INICIO DOS TESTES DOS REGISTRADORES ESTRUTURAIS DO NEANDER (ID 7)");
        $display("================================================================================");

        // Inicializacao dos sinais
        clk      = 0;
        rst_n    = 0;
        load_gen = 0; d_gen = 8'h00;
        cargaAC  = 0; d_ac  = 8'h00;
        cargaRDM = 0; d_rdm = 8'h00;
        cargaREM = 0; d_rem = 8'h00;
        cargaRI  = 0; d_ri  = 8'h00;

        // ---------------------------------------------------------------------
        // 1. Reset Inicial Assincrono
        // ---------------------------------------------------------------------
        $display("\n--- 1. Testes de Reset Inicial Assincrono (rst_n = 0) ---");
        #10;
        checar(q_gen, 8'h00, "reg8: Saida zerada pelo reset inicial");
        checar(q_ac,  8'h00, "AC: Saida zerada pelo reset inicial");
        checar(q_rdm, 8'h00, "RDM: Saida zerada pelo reset inicial");
        checar(q_rem, 8'h00, "REM: Saida zerada pelo reset inicial");
        checar(q_ri,  8'h00, "RI: Saida zerada pelo reset inicial");

        // Libera reset
        rst_n = 1;
        #10;

        // ---------------------------------------------------------------------
        // 2. Testes de Retencao de Dados (Hold: load = 0)
        // ---------------------------------------------------------------------
        $display("\n--- 2. Testes de Retencao (Hold: load = 0) no reg8 ---");
        load_gen = 0;
        d_gen = 8'hAA; clock_pulse;
        checar(q_gen, 8'h00, "reg8: Mantem 00 com d=AA e load=0");

        d_gen = 8'hFF; clock_pulse;
        checar(q_gen, 8'h00, "reg8: Mantem 00 com d=FF e load=0");

        // ---------------------------------------------------------------------
        // 3. Testes de Carga Sincrona no reg8 (load = 1)
        // ---------------------------------------------------------------------
        $display("\n--- 3. Testes de Carga Sincrona (load = 1) no reg8 ---");
        load_gen = 1;
        d_gen = 8'hA5; clock_pulse;
        checar(q_gen, 8'hA5, "reg8: Carga sincrona com 0xA5");

        d_gen = 8'h5A; clock_pulse;
        checar(q_gen, 8'h5A, "reg8: Carga sincrona com 0x5A");

        // Desativa load e altera entrada: valor deve persistir
        load_gen = 0;
        d_gen = 8'h12; clock_pulse;
        checar(q_gen, 8'h5A, "reg8: Retencao de 0x5A apos desativar load");

        // ---------------------------------------------------------------------
        // 4. Teste de Reset Assincrono Durante Operacao
        // ---------------------------------------------------------------------
        $display("\n--- 4. Teste de Reset Assincrono com Valor Carregado ---");
        // Com clk=0 estavel, ativa rst_n=0: deve zerar sem esperar pulso de clock
        rst_n = 0; #2;
        checar(q_gen, 8'h00, "reg8: Limpeza assincrona imediata (sem clock)");
        rst_n = 1; #5;

        // ---------------------------------------------------------------------
        // 5. Testes de Walking 1s e Walking 0s no reg8
        // ---------------------------------------------------------------------
        $display("\n--- 5. Walking 1s (individual bit check) no reg8 ---");
        load_gen = 1;
        for (i = 0; i < 8; i = i + 1) begin
            d_gen = (1 << i);
            clock_pulse;
            checar(q_gen, (1 << i), "reg8: Bit individual em 1");
        end

        $display("\n--- 6. Walking 0s (individual bit clear check) no reg8 ---");
        for (i = 0; i < 8; i = i + 1) begin
            d_gen = ~(1 << i);
            clock_pulse;
            checar(q_gen, 8'hFF & ~(1 << i), "reg8: Bit individual em 0");
        end

        // ---------------------------------------------------------------------
        // 7. Testes Individuais de AC, RDM, REM e RI
        // ---------------------------------------------------------------------
        $display("\n--- 7. Testes de Carga e Isolamento em AC, RDM, REM e RI ---");

        // 7.1 Carga exclusiva no AC
        d_ac = 8'h42; d_rdm = 8'h11; d_rem = 8'h22; d_ri = 8'h33;
        cargaAC = 1; cargaRDM = 0; cargaREM = 0; cargaRI = 0;
        clock_pulse;
        checar(q_ac,  8'h42, "AC: Carregado com 0x42 via cargaAC");
        checar(q_rdm, 8'h00, "RDM: Nao alterado durante cargaAC (permanece 00)");
        checar(q_rem, 8'h00, "REM: Nao alterado durante cargaAC (permanece 00)");
        checar(q_ri,  8'h00, "RI: Nao alterado durante cargaAC (permanece 00)");

        // 7.2 Carga exclusiva no RDM
        cargaAC = 0; cargaRDM = 1; cargaREM = 0; cargaRI = 0;
        clock_pulse;
        checar(q_ac,  8'h42, "AC: Retem 0x42 durante cargaRDM");
        checar(q_rdm, 8'h11, "RDM: Carregado com 0x11 via cargaRDM");
        checar(q_rem, 8'h00, "REM: Permanece 00");
        checar(q_ri,  8'h00, "RI: Permanece 00");

        // 7.3 Carga exclusiva no REM
        cargaAC = 0; cargaRDM = 0; cargaREM = 1; cargaRI = 0;
        clock_pulse;
        checar(q_ac,  8'h42, "AC: Retem 0x42 durante cargaREM");
        checar(q_rdm, 8'h11, "RDM: Retem 0x11 durante cargaREM");
        checar(q_rem, 8'h22, "REM: Carregado com 0x22 via cargaREM");
        checar(q_ri,  8'h00, "RI: Permanece 00");

        // 7.4 Carga exclusiva no RI
        cargaAC = 0; cargaRDM = 0; cargaREM = 0; cargaRI = 1;
        clock_pulse;
        checar(q_ac,  8'h42, "AC: Retem 0x42 durante cargaRI");
        checar(q_rdm, 8'h11, "RDM: Retem 0x11 durante cargaRI");
        checar(q_rem, 8'h22, "REM: Retem 0x22 durante cargaRI");
        checar(q_ri,  8'h33, "RI: Carregado com 0x33 via cargaRI");

        // 7.5 Reset assincrono simultaneo em todos
        $display("\n--- 8. Reset Assincrono Simultaneo em Todos os Registradores ---");
        cargaAC = 0; cargaRDM = 0; cargaREM = 0; cargaRI = 0;
        rst_n = 0; #2;
        checar(q_ac,  8'h00, "AC: Zerado por reset geral");
        checar(q_rdm, 8'h00, "RDM: Zerado por reset geral");
        checar(q_rem, 8'h00, "REM: Zerado por reset geral");
        checar(q_ri,  8'h00, "RI: Zerado por reset geral");
        checar(q_gen, 8'h00, "reg8: Zerado por reset geral");

        // ---------------------------------------------------------------------
        // Resumo dos Resultados
        // ---------------------------------------------------------------------
        $display("\n================================================================================");
        $display("  RESUMO DOS TESTES DOS REGISTRADORES:");
        $display("  Total de Verificacoes : %0d", total);
        $display("  Aprovadas             : %0d", total - erros);
        $display("  Falhas                : %0d", erros);
        $display("================================================================================");

        if (erros == 0)
            $display(">>> SUCESSO: Todos os testes dos registradores passaram com exito! <<<\n");
        else
            $display(">>> FALHA: Detectados erros na execucao dos testes dos registradores! <<<\n");

        $finish;
    end

endmodule
