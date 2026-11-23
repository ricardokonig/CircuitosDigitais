`timescale 1ns/1ns

module tb_flags;

    reg clk;
    reg rst_n;
    reg cargaNZ;
    reg in_n;
    reg in_z;
    wire flag_n;
    wire flag_z;

    integer total_tests = 0;
    integer passed_tests = 0;

    reg_flags dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .cargaNZ (cargaNZ),
        .in_n    (in_n),
        .in_z    (in_z),
        .flag_n  (flag_n),
        .flag_z  (flag_z)
    );

    // Gerador de clock (periodo = 10ns)
    always #5 clk = ~clk;

    task checar;
        input exp_n;
        input exp_z;
        input [8*60:1] nome;
        begin
            total_tests = total_tests + 1;
            if (flag_n === exp_n && flag_z === exp_z) begin
                passed_tests = passed_tests + 1;
                $display("  [PASSOU] %0s -> flag_n=%b, flag_z=%b", nome, flag_n, flag_z);
            end else begin
                $display("  [FALHOU] %0s -> Obteve: N=%b Z=%b | Esperado: N=%b Z=%b",
                         nome, flag_n, flag_z, exp_n, exp_z);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_flags.vcd");
        $dumpvars(0, tb_flags);

        $display("================================================================================");
        $display("  INICIO DOS TESTES DO REGISTRADOR DE FLAGS (ID 9)");
        $display("================================================================================");

        clk = 0;
        rst_n = 0;
        cargaNZ = 0;
        in_n = 0;
        in_z = 0;
        #12;

        // 1. Reset assincrono inicial
        checar(0, 0, "1. Reset assincrono inicial (N=0, Z=0)");

        rst_n = 1;
        #10;

        // 2. Retencao com cargaNZ = 0
        in_n = 1; in_z = 1;
        @(posedge clk); #1;
        checar(0, 0, "2. Retencao com cargaNZ=0 (entradas 1,1 ignoradas)");

        // 3. Carga de N=1, Z=0
        cargaNZ = 1; in_n = 1; in_z = 0;
        @(posedge clk); #1;
        checar(1, 0, "3. Carga com sucesso: N=1, Z=0");

        // 4. Retencao do valor anterior
        cargaNZ = 0; in_n = 0; in_z = 1;
        @(posedge clk); #1;
        checar(1, 0, "4. Retencao de N=1, Z=0 mesmo com entradas alteradas");

        // 5. Carga de N=0, Z=1
        cargaNZ = 1; in_n = 0; in_z = 1;
        @(posedge clk); #1;
        checar(0, 1, "5. Carga com sucesso: N=0, Z=1");

        // 6. Carga de N=1, Z=1
        cargaNZ = 1; in_n = 1; in_z = 1;
        @(posedge clk); #1;
        checar(1, 1, "6. Carga com sucesso: N=1, Z=1");

        // 7. Carga de N=0, Z=0
        cargaNZ = 1; in_n = 0; in_z = 0;
        @(posedge clk); #1;
        checar(0, 0, "7. Carga com sucesso: N=0, Z=0");

        // 8. Teste de Reset Assincrono forcado com carga em 1
        cargaNZ = 1; in_n = 1; in_z = 1;
        @(posedge clk); #1;
        checar(1, 1, "8. Flags setados para 1,1 antes do reset");

        #3;
        rst_n = 0; // Ativa reset fora da borda do clock
        #1;
        checar(0, 0, "8.1 Reset assincrono imediato (retorno a 0,0 fora de borda)");

        #10;
        rst_n = 1;
        cargaNZ = 0;
        @(posedge clk); #1;
        checar(0, 0, "8.2 Mantem 0,0 apos liberacao do reset");

        $display("================================================================================");
        $display("  RESUMO DOS TESTES DO REGISTRADOR DE FLAGS:");
        $display("  Total de Verificacoes : %0d", total_tests);
        $display("  Aprovadas             : %0d", passed_tests);
        $display("  Falhas                : %0d", total_tests - passed_tests);
        $display("================================================================================");

        if (passed_tests == total_tests) begin
            $display(">>> SUCESSO: Todos os testes do Registrador de Flags passaram com exito! <<<\n");
        end else begin
            $display(">>> FALHA: Houve erros no teste do Registrador de Flags! <<<\n");
        end

        $finish;
    end

endmodule
