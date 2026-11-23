`timescale 1ns/1ns

module tb_mux_rem;

    // Sinais de estimulo para mux2x1_8b
    reg  [7:0] d0;
    reg  [7:0] d1;
    reg        sel;
    wire [7:0] out;

    // Sinais de estimulo para mux_rem
    reg  [7:0] pc;
    reg  [7:0] rdm;
    reg        sel_rem;
    wire [7:0] rem;

    integer total = 0;
    integer erros = 0;

    // 1. Instancia do mux2x1_8b
    mux2x1_8b dut_mux (
        .d0(d0),
        .d1(d1),
        .sel(sel),
        .out(out)
    );

    // 2. Instancia do mux_rem
    mux_rem dut_rem (
        .pc(pc),
        .rdm(rdm),
        .sel(sel_rem),
        .rem(rem)
    );

    // Tarefa de checagem para mux2x1_8b
    task checar_mux2x1;
        input [7:0] exp_out;
        input [80*8:1] nome_teste;
        begin
            total = total + 1;
            #5; // Aguarda propagacao combinacional
            if (out !== exp_out) begin
                $display("  [FALHOU] %0s | sel=%b, d0=%h, d1=%h | Esperado: %h | Obtido: %h",
                         nome_teste, sel, d0, d1, exp_out, out);
                erros = erros + 1;
            end else begin
                $display("  [PASSOU] %0s | sel=%b -> out=%h", nome_teste, sel, out);
            end
        end
    endtask

    // Tarefa de checagem para mux_rem
    task checar_mux_rem;
        input [7:0] exp_rem;
        input [80*8:1] nome_teste;
        begin
            total = total + 1;
            #5; // Aguarda propagacao combinacional
            if (rem !== exp_rem) begin
                $display("  [FALHOU] %0s | sel=%b, pc=%h, rdm=%h | Esperado: %h | Obtido: %h",
                         nome_teste, sel_rem, pc, rdm, exp_rem, rem);
                erros = erros + 1;
            end else begin
                $display("  [PASSOU] %0s | sel=%b -> rem=%h", nome_teste, sel_rem, rem);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_mux_rem.vcd");
        $dumpvars(0, tb_mux_rem);

        $display("================================================================================");
        $display("  INICIO DOS TESTES DO MUX DO REM (NEANDER)");
        $display("================================================================================");

        // =====================================================================
        // SECAO 1: Testes unitarios do mux2x1_8b com sel = 0 (Seleciona d0 / PC)
        // =====================================================================
        $display("\n--------------------------------------------------------------------------------");
        $display(" [SECAO 1] TESTES DO MUX2X1_8B COM SEL = 0 (SELECIONA d0)");
        $display("--------------------------------------------------------------------------------");

        sel = 1'b0; d0 = 8'h00; d1 = 8'hFF;
        checar_mux2x1(8'h00, "1.1: sel=0 seleciona d0=0x00 (d1=0xFF)");

        sel = 1'b0; d0 = 8'hAA; d1 = 8'h55;
        checar_mux2x1(8'hAA, "1.2: sel=0 seleciona d0=0xAA (d1=0x55)");

        sel = 1'b0; d0 = 8'h12; d1 = 8'h34;
        checar_mux2x1(8'h12, "1.3: sel=0 seleciona d0=0x12 (d1=0x34)");

        // Teste de imunidade a ruido/variacao em d1 quando sel=0
        sel = 1'b0; d0 = 8'h42; d1 = 8'h00; #2;
        d1 = 8'hFF; #2;
        d1 = 8'hAA;
        checar_mux2x1(8'h42, "1.4: sel=0 isola variacao em d1 (d0=0x42 mantido)");

        // =====================================================================
        // SECAO 2: Testes unitarios do mux2x1_8b com sel = 1 (Seleciona d1 / RDM)
        // =====================================================================
        $display("\n--------------------------------------------------------------------------------");
        $display(" [SECAO 2] TESTES DO MUX2X1_8B COM SEL = 1 (SELECIONA d1)");
        $display("--------------------------------------------------------------------------------");

        sel = 1'b1; d0 = 8'h00; d1 = 8'hFF;
        checar_mux2x1(8'hFF, "2.1: sel=1 seleciona d1=0xFF (d0=0x00)");

        sel = 1'b1; d0 = 8'hAA; d1 = 8'h55;
        checar_mux2x1(8'h55, "2.2: sel=1 seleciona d1=0x55 (d0=0xAA)");

        sel = 1'b1; d0 = 8'h12; d1 = 8'h80;
        checar_mux2x1(8'h80, "2.3: sel=1 seleciona d1=0x80 (d0=0x12)");

        // Teste de imunidade a ruido/variacao em d0 quando sel=1
        sel = 1'b1; d0 = 8'h00; d1 = 8'hC7; #2;
        d0 = 8'hFF; #2;
        d0 = 8'h55;
        checar_mux2x1(8'hC7, "2.4: sel=1 isola variacao em d0 (d1=0xC7 mantido)");

        // =====================================================================
        // SECAO 3: Testes do modulo semantico mux_rem (portas pc, rdm, rem)
        // =====================================================================
        $display("\n--------------------------------------------------------------------------------");
        $display(" [SECAO 3] TESTES DO MODULO SEMANTICO MUX_REM");
        $display("--------------------------------------------------------------------------------");

        sel_rem = 1'b0; pc = 8'h10; rdm = 8'h80;
        checar_mux_rem(8'h10, "3.1: mux_rem sel=0 roteia PC=0x10 para REM");

        sel_rem = 1'b1; pc = 8'h10; rdm = 8'h80;
        checar_mux_rem(8'h80, "3.2: mux_rem sel=1 roteia RDM=0x80 para REM");

        sel_rem = 1'b0; pc = 8'hFE; rdm = 8'h20;
        checar_mux_rem(8'hFE, "3.3: mux_rem volta sel=0 roteia PC=0xFE para REM");

        sel_rem = 1'b1; pc = 8'hFE; rdm = 8'h20;
        checar_mux_rem(8'h20, "3.4: mux_rem volta sel=1 roteia RDM=0x20 para REM");

        // =====================================================================
        // SECAO 4: Simulacao de Ciclos Reais do Neander
        // =====================================================================
        $display("\n--------------------------------------------------------------------------------");
        $display(" [SECAO 4] SIMULACAO DE CICLOS REAIS DO NEANDER (FETCH E ACESSO A DADO)");
        $display("--------------------------------------------------------------------------------");

        // Passo t0: Fetch do Opcode -> REM recebe PC
        pc = 8'h00; rdm = 8'hXX; sel_rem = 1'b0;
        checar_mux_rem(8'h00, "4.1: Ciclo t0 (Fetch Opcode) -> REM = PC (0x00)");

        // Passo t3: Fetch do Endereco do Operando -> REM recebe PC incrementado
        pc = 8'h01; rdm = 8'hXX; sel_rem = 1'b0;
        checar_mux_rem(8'h01, "4.2: Ciclo t3 (Fetch Operando) -> REM = PC (0x01)");

        // Passo t5: Acesso ao Dado -> RDM contem 0x80 (lido no t4); REM recebe RDM
        pc = 8'h02; rdm = 8'h80; sel_rem = 1'b1;
        checar_mux_rem(8'h80, "4.3: Ciclo t5 (Acesso a Dado) -> REM = RDM (0x80)");

        // Retorno ao ciclo t0 da proxima instrucao -> sel volta a 0
        pc = 8'h02; rdm = 8'h80; sel_rem = 1'b0;
        checar_mux_rem(8'h02, "4.4: Ciclo t0 seguinte -> REM volta a receber PC (0x02)");

        // =====================================================================
        // SECAO 5: Varredura de Padroes Bit a Bit (Walking Ones / Zeros)
        // =====================================================================
        $display("\n--------------------------------------------------------------------------------");
        $display(" [SECAO 5] TESTE DE PADROES (WALKING ONES)");
        $display("--------------------------------------------------------------------------------");

        begin : walking_test
            integer bit_idx;
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                d0 = (1 << bit_idx);
                d1 = ~(1 << bit_idx);

                sel = 1'b0;
                checar_mux2x1((1 << bit_idx), "5.x: Walking 1 no d0 com sel=0");

                sel = 1'b1;
                checar_mux2x1(~(1 << bit_idx) & 8'hFF, "5.x: Walking 0 no d1 com sel=1");
            end
        end

        // =====================================================================
        // RELATORIO FINAL
        // =====================================================================
        $display("\n================================================================================");
        $display("  RELATORIO FINAL DOS TESTES DO MUX DO REM");
        $display("================================================================================");
        $display("  Total de Verificacoes : %0d", total);
        $display("  Passaram              : %0d", total - erros);
        $display("  Falharam              : %0d", erros);
        $display("");
        if (erros == 0) begin
            $display("  >>> SUCESSO: TODOS OS TESTES DO MUX PASSARAM! DESIGN VALIDADO! <<<");
        end else begin
            $display("  >>> ATENCAO: FORAM ENCONTRADOS %0d ERROS NOS TESTES! <<<", erros);
        end
        $display("================================================================================\n");

        $finish;
    end

endmodule
