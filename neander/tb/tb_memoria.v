`timescale 1ns/1ns

module tb_memoria;

    reg        clk;
    reg        rst_n;
    reg        read;
    reg        write;
    reg  [7:0] addr;
    reg  [7:0] data_in;
    wire [7:0] data_out;

    integer total_tests = 0;
    integer passed_tests = 0;

    memoria dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .read     (read),
        .write    (write),
        .addr     (addr),
        .data_in  (data_in),
        .data_out (data_out)
    );

    always #5 clk = ~clk;

    task checar;
        input [7:0] exp_data;
        input [8*60:1] nome;
        begin
            total_tests = total_tests + 1;
            if (data_out === exp_data) begin
                passed_tests = passed_tests + 1;
                $display("  [PASSOU] %0s -> data_out = 0x%02X", nome, data_out);
            end else begin
                $display("  [FALHOU] %0s -> data_out = 0x%02X (esperado: 0x%02X)", nome, data_out, exp_data);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_memoria.vcd");
        $dumpvars(0, tb_memoria);

        $display("================================================================================");
        $display("  INICIO DOS TESTES DA MEMORIA DO NEANDER");
        $display("================================================================================");

        clk = 0;
        rst_n = 0;
        read = 0;
        write = 0;
        addr = 8'h00;
        data_in = 8'h00;
        #12;
        rst_n = 1;
        #5;

        // 1. Leitura com read=0 (deve retornar 0x00)
        addr = 8'h00; read = 0; #5;
        checar(8'h00, "1. Leitura desabilitada com read=0");

        // 2. Leitura das instrucoes do programa pre-carregado
        read = 1;
        addr = 8'h00; #5; checar(8'h20, "2.1 Endereco 0x00 (Opcode LDA)");
        addr = 8'h01; #5; checar(8'h80, "2.2 Endereco 0x01 (Operando 0x80)");
        addr = 8'h02; #5; checar(8'h30, "2.3 Endereco 0x02 (Opcode ADD)");
        addr = 8'h04; #5; checar(8'h10, "2.4 Endereco 0x04 (Opcode STA)");
        addr = 8'h06; #5; checar(8'h60, "2.5 Endereco 0x06 (Opcode NOT)");
        addr = 8'h07; #5; checar(8'h90, "2.6 Endereco 0x07 (Opcode JN)");
        addr = 8'h0B; #5; checar(8'h50, "2.7 Endereco 0x0B (Opcode AND)");
        addr = 8'h0D; #5; checar(8'hA0, "2.8 Endereco 0x0D (Opcode JZ)");
        addr = 8'h11; #5; checar(8'h40, "2.9 Endereco 0x11 (Opcode OR)");
        addr = 8'h13; #5; checar(8'hF0, "2.10 Endereco 0x13 (Opcode HLT)");

        // 3. Leitura da area de dados inicial
        addr = 8'h80; #5; checar(8'h05, "3.1 Dado em 0x80 (Valor 5)");
        addr = 8'h81; #5; checar(8'h03, "3.2 Dado em 0x81 (Valor 3)");
        addr = 8'h82; #5; checar(8'h00, "3.3 Dado em 0x82 (Valor inicial 0)");

        // 4. Teste de Escrita Sincrona (simulando STA no endereco 0x82)
        read = 0;
        addr = 8'h82;
        data_in = 8'h08; // Escreve o resultado 8 (5 + 3)
        write = 1;
        @(posedge clk); #1; // Borda de subida do clock para gravar
        write = 0;

        // 4.1 Ler de volta e verificar gravacao
        read = 1;
        addr = 8'h82; #5;
        checar(8'h08, "4.1 Leitura pos-escrita em 0x82 (Valor gravado 8)");

        // 5. Teste de Escrita em outro endereco (0x99 com valor 0xBE)
        read = 0;
        addr = 8'h99;
        data_in = 8'hBE;
        write = 1;
        @(posedge clk); #1;
        write = 0;

        read = 1;
        addr = 8'h99; #5;
        checar(8'hBE, "5.1 Leitura pos-escrita em 0x99 (Valor gravado 0xBE)");

        // 6. Teste de Reset geral recarregando a memoria padrao
        rst_n = 0; #10; rst_n = 1; #5;
        addr = 8'h82; #5;
        checar(8'h00, "6.1 Posicao 0x82 reinicializada para 0 apos reset");
        addr = 8'h00; #5;
        checar(8'h20, "6.2 Posicao 0x00 preserva LDA apos reset");

        $display("================================================================================");
        $display("  RESUMO DOS TESTES DA MEMORIA:");
        $display("  Total de Verificacoes : %0d", total_tests);
        $display("  Aprovadas             : %0d", passed_tests);
        $display("  Falhas                : %0d", total_tests - passed_tests);
        $display("================================================================================");

        if (passed_tests == total_tests) begin
            $display(">>> SUCESSO: Todos os testes da Memoria passaram com exito! <<<\n");
        end else begin
            $display(">>> FALHA: Houve erros no teste da Memoria! <<<\n");
        end

        $finish;
    end

endmodule
