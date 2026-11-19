`timescale 1ns/1ns

module tb_controle;

    // =========================================================================
    // Sinais para Teste Unitario do Temporizador
    // =========================================================================
    reg        temp_clk;
    reg        temp_rst_n;
    reg        temp_goto_t0;
    reg        temp_hlt;
    wire       temp_t0, temp_t1, temp_t2, temp_t3;
    wire       temp_t4, temp_t5, temp_t6, temp_t7;
    wire [7:0] temp_estado;
    assign temp_estado = {temp_t7, temp_t6, temp_t5, temp_t4,
                          temp_t3, temp_t2, temp_t1, temp_t0};

    temporizador u_temp_dut (
        .clk     (temp_clk),
        .rst_n   (temp_rst_n),
        .goto_t0 (temp_goto_t0),
        .hlt     (temp_hlt),
        .t0      (temp_t0),
        .t1      (temp_t1),
        .t2      (temp_t2),
        .t3      (temp_t3),
        .t4      (temp_t4),
        .t5      (temp_t5),
        .t6      (temp_t6),
        .t7      (temp_t7)
    );

    // =========================================================================
    // Sinais para Teste do Decodificador de Instrucoes (decod_inst)
    // =========================================================================
    reg  [3:0] decod_op;
    wire       d_nop, d_sta, d_lda, d_add, d_or_op, d_and_op, d_not_op;
    wire       d_jmp, d_jn, d_jz, d_hlt;
    wire [10:0] d_todas;
    assign d_todas = {d_hlt, d_jz, d_jn, d_jmp, d_not_op, d_and_op,
                      d_or_op, d_add, d_lda, d_sta, d_nop};

    decod_inst u_decod_dut (
        .op     (decod_op),
        .nop    (d_nop),
        .sta    (d_sta),
        .lda    (d_lda),
        .add    (d_add),
        .or_op  (d_or_op),
        .and_op (d_and_op),
        .not_op (d_not_op),
        .jmp    (d_jmp),
        .jn     (d_jn),
        .jz     (d_jz),
        .hlt    (d_hlt)
    );

    // =========================================================================
    // Sinais para Teste Unitario da Unidade de Controle Combinacional
    // =========================================================================
    reg  uc_t0, uc_t1, uc_t2, uc_t3, uc_t4, uc_t5, uc_t6, uc_t7;
    reg  uc_nop, uc_sta, uc_lda, uc_add, uc_or_op, uc_and_op, uc_not_op;
    reg  uc_jmp, uc_jn, uc_jz;
    reg  uc_n_flag, uc_z_flag;

    wire uc_cargaPC;
    wire uc_incrementaPC;
    wire uc_sel;
    wire uc_cargaREM;
    wire uc_read;
    wire uc_write;
    wire uc_cargaRDM;
    wire uc_cargaAC;
    wire uc_cargaNZ;
    wire uc_cargaRI;
    wire uc_goto_t0;
    wire uc_ula_y;
    wire uc_ula_add;
    wire uc_ula_and;
    wire uc_ula_or;
    wire uc_ula_not;

    unidade_controle u_uc_dut (
        .t0           (uc_t0),
        .t1           (uc_t1),
        .t2           (uc_t2),
        .t3           (uc_t3),
        .t4           (uc_t4),
        .t5           (uc_t5),
        .t6           (uc_t6),
        .t7           (uc_t7),
        .nop          (uc_nop),
        .sta          (uc_sta),
        .lda          (uc_lda),
        .add          (uc_add),
        .or_op        (uc_or_op),
        .and_op       (uc_and_op),
        .not_op       (uc_not_op),
        .jmp          (uc_jmp),
        .jn           (uc_jn),
        .jz           (uc_jz),
        .n_flag       (uc_n_flag),
        .z_flag       (uc_z_flag),
        .cargaPC      (uc_cargaPC),
        .incrementaPC (uc_incrementaPC),
        .sel          (uc_sel),
        .cargaREM     (uc_cargaREM),
        .read         (uc_read),
        .write        (uc_write),
        .cargaRDM     (uc_cargaRDM),
        .cargaAC      (uc_cargaAC),
        .cargaNZ      (uc_cargaNZ),
        .cargaRI      (uc_cargaRI),
        .goto_t0      (uc_goto_t0),
        .ula_y        (uc_ula_y),
        .ula_add      (uc_ula_add),
        .ula_and      (uc_ula_and),
        .ula_or       (uc_ula_or),
        .ula_not      (uc_ula_not)
    );

    // =========================================================================
    // Sinais para Teste Integrado (controle_top)
    // =========================================================================
    reg        top_clk;
    reg        top_rst_n;
    reg  [3:0] top_opcode;
    reg        top_flag_n;
    reg        top_flag_z;

    wire       top_cargaPC;
    wire       top_incrementaPC;
    wire       top_sel;
    wire       top_cargaREM;
    wire       top_read;
    wire       top_write;
    wire       top_cargaRDM;
    wire       top_cargaAC;
    wire       top_cargaNZ;
    wire       top_cargaRI;
    wire       top_goto_t0;
    wire       top_ula_y;
    wire       top_ula_add;
    wire       top_ula_and;
    wire       top_ula_or;
    wire       top_ula_not;
    wire [2:0] top_selUAL;
    wire [7:0] top_estado_t;

    controle_top u_top_dut (
        .clk          (top_clk),
        .rst_n        (top_rst_n),
        .opcode       (top_opcode),
        .flag_n       (top_flag_n),
        .flag_z       (top_flag_z),
        .cargaPC      (top_cargaPC),
        .incrementaPC (top_incrementaPC),
        .sel          (top_sel),
        .cargaREM     (top_cargaREM),
        .read         (top_read),
        .write        (top_write),
        .cargaRDM     (top_cargaRDM),
        .cargaAC      (top_cargaAC),
        .cargaNZ      (top_cargaNZ),
        .cargaRI      (top_cargaRI),
        .goto_t0      (top_goto_t0),
        .ula_y        (top_ula_y),
        .ula_add      (top_ula_add),
        .ula_and      (top_ula_and),
        .ula_or       (top_ula_or),
        .ula_not      (top_ula_not),
        .selUAL       (top_selUAL),
        .estado_t     (top_estado_t)
    );

    // =========================================================================
    // Geradores de Clock (Periodo = 20ns)
    // =========================================================================
    always #10 temp_clk = ~temp_clk;
    always #10 top_clk  = ~top_clk;

    // =========================================================================
    // Variaveis de Controle de Testes
    // =========================================================================
    integer total_tests;
    integer pass_tests;
    integer fail_tests;

    // =========================================================================
    // Tarefas Auxiliares para Verificacoes
    // =========================================================================

    // Verifica estado do temporizador (one-hot)
    task check_temporizador;
        input [7:0] exp_estado;
        input [8*80:1] test_name;
        begin
            total_tests = total_tests + 1;
            if (temp_estado === exp_estado) begin
                pass_tests = pass_tests + 1;
                $display("  [PASSOU] %0s -> estado=%b", test_name, temp_estado);
            end else begin
                fail_tests = fail_tests + 1;
                $display("  [FALHA ] %0s -> esperado=%b, obtido=%b (t=%0t)",
                         test_name, exp_estado, temp_estado, $time);
            end
        end
    endtask

    // Verifica decodificacao de opcode
    task check_decod;
        input [10:0] exp_linhas; // {hlt, jz, jn, jmp, not, and, or, add, lda, sta, nop}
        input [8*80:1] test_name;
        begin
            total_tests = total_tests + 1;
            if (d_todas === exp_linhas) begin
                pass_tests = pass_tests + 1;
                $display("  [PASSOU] %0s -> linhas={hlt,jz,jn,jmp,not,and,or,add,lda,sta,nop}=%b", test_name, d_todas);
            end else begin
                fail_tests = fail_tests + 1;
                $display("  [FALHA ] %0s -> esperado=%b, obtido=%b", test_name, exp_linhas, d_todas);
            end
        end
    endtask

    // Limpa todas as instrucoes da unidade de controle
    task clear_uc_inputs;
        begin
            uc_t0 = 0; uc_t1 = 0; uc_t2 = 0; uc_t3 = 0;
            uc_t4 = 0; uc_t5 = 0; uc_t6 = 0; uc_t7 = 0;
            uc_nop = 0; uc_sta = 0; uc_lda = 0; uc_add = 0;
            uc_or_op = 0; uc_and_op = 0; uc_not_op = 0;
            uc_jmp = 0; uc_jn = 0; uc_jz = 0;
            uc_n_flag = 0; uc_z_flag = 0;
        end
    endtask

    // Define qual pulso de tempo t0..t7 esta ativo na UC
    task set_uc_t;
        input integer t_num;
        begin
            uc_t0 = (t_num == 0);
            uc_t1 = (t_num == 1);
            uc_t2 = (t_num == 2);
            uc_t3 = (t_num == 3);
            uc_t4 = (t_num == 4);
            uc_t5 = (t_num == 5);
            uc_t6 = (t_num == 6);
            uc_t7 = (t_num == 7);
        end
    endtask

    // Verifica todos os 16 sinais gerados pela UC
    task check_uc_signals;
        input exp_cargaPC;
        input exp_incrementaPC;
        input exp_sel;
        input exp_cargaREM;
        input exp_read;
        input exp_write;
        input exp_cargaRDM;
        input exp_cargaAC;
        input exp_cargaNZ;
        input exp_cargaRI;
        input exp_goto_t0;
        input exp_ula_y;
        input exp_ula_add;
        input exp_ula_and;
        input exp_ula_or;
        input exp_ula_not;
        input [8*80:1] step_name;

        reg ok;
        begin
            total_tests = total_tests + 1;
            ok = 1;

            if (uc_cargaPC      !== exp_cargaPC)      begin ok = 0; $display("    cargaPC      = %b (esp: %b)", uc_cargaPC, exp_cargaPC); end
            if (uc_incrementaPC !== exp_incrementaPC) begin ok = 0; $display("    incrementaPC = %b (esp: %b)", uc_incrementaPC, exp_incrementaPC); end
            if (uc_sel          !== exp_sel)          begin ok = 0; $display("    sel          = %b (esp: %b)", uc_sel, exp_sel); end
            if (uc_cargaREM     !== exp_cargaREM)     begin ok = 0; $display("    cargaREM     = %b (esp: %b)", uc_cargaREM, exp_cargaREM); end
            if (uc_read         !== exp_read)         begin ok = 0; $display("    read         = %b (esp: %b)", uc_read, exp_read); end
            if (uc_write        !== exp_write)        begin ok = 0; $display("    write        = %b (esp: %b)", uc_write, exp_write); end
            if (uc_cargaRDM     !== exp_cargaRDM)     begin ok = 0; $display("    cargaRDM     = %b (esp: %b)", uc_cargaRDM, exp_cargaRDM); end
            if (uc_cargaAC      !== exp_cargaAC)      begin ok = 0; $display("    cargaAC      = %b (esp: %b)", uc_cargaAC, exp_cargaAC); end
            if (uc_cargaNZ      !== exp_cargaNZ)      begin ok = 0; $display("    cargaNZ      = %b (esp: %b)", uc_cargaNZ, exp_cargaNZ); end
            if (uc_cargaRI      !== exp_cargaRI)      begin ok = 0; $display("    cargaRI      = %b (esp: %b)", uc_cargaRI, exp_cargaRI); end
            if (uc_goto_t0      !== exp_goto_t0)      begin ok = 0; $display("    goto_t0      = %b (esp: %b)", uc_goto_t0, exp_goto_t0); end
            if (uc_ula_y        !== exp_ula_y)        begin ok = 0; $display("    ula_y        = %b (esp: %b)", uc_ula_y, exp_ula_y); end
            if (uc_ula_add      !== exp_ula_add)      begin ok = 0; $display("    ula_add      = %b (esp: %b)", uc_ula_add, exp_ula_add); end
            if (uc_ula_and      !== exp_ula_and)      begin ok = 0; $display("    ula_and      = %b (esp: %b)", uc_ula_and, exp_ula_and); end
            if (uc_ula_or       !== exp_ula_or)       begin ok = 0; $display("    ula_or       = %b (esp: %b)", uc_ula_or, exp_ula_or); end
            if (uc_ula_not      !== exp_ula_not)      begin ok = 0; $display("    ula_not      = %b (esp: %b)", uc_ula_not, exp_ula_not); end

            if (ok) begin
                pass_tests = pass_tests + 1;
                $display("  [PASSOU] %0s", step_name);
            end else begin
                fail_tests = fail_tests + 1;
                $display("  [FALHA ] %0s (t=%0t)", step_name, $time);
            end
        end
    endtask

    // Verifica estado e sinais do top-level
    task check_top_step;
        input [7:0] exp_estado_t;
        input       exp_goto_t0;
        input       exp_cargaPC;
        input       exp_incrementaPC;
        input       exp_sel;
        input       exp_cargaREM;
        input       exp_read;
        input       exp_write;
        input       exp_cargaRDM;
        input       exp_cargaAC;
        input       exp_cargaNZ;
        input       exp_cargaRI;
        input [2:0] exp_selUAL;
        input [8*80:1] step_name;

        reg ok;
        begin
            total_tests = total_tests + 1;
            ok = 1;

            if (top_estado_t    !== exp_estado_t)    begin ok = 0; $display("    estado_t     = %b (esp: %b)", top_estado_t, exp_estado_t); end
            if (top_goto_t0     !== exp_goto_t0)     begin ok = 0; $display("    goto_t0      = %b (esp: %b)", top_goto_t0, exp_goto_t0); end
            if (top_cargaPC     !== exp_cargaPC)     begin ok = 0; $display("    cargaPC      = %b (esp: %b)", top_cargaPC, exp_cargaPC); end
            if (top_incrementaPC!== exp_incrementaPC)begin ok = 0; $display("    incrementaPC = %b (esp: %b)", top_incrementaPC, exp_incrementaPC); end
            if (top_sel         !== exp_sel)         begin ok = 0; $display("    sel          = %b (esp: %b)", top_sel, exp_sel); end
            if (top_cargaREM    !== exp_cargaREM)    begin ok = 0; $display("    cargaREM     = %b (esp: %b)", top_cargaREM, exp_cargaREM); end
            if (top_read        !== exp_read)        begin ok = 0; $display("    read         = %b (esp: %b)", top_read, exp_read); end
            if (top_write       !== exp_write)       begin ok = 0; $display("    write        = %b (esp: %b)", top_write, exp_write); end
            if (top_cargaRDM    !== exp_cargaRDM)    begin ok = 0; $display("    cargaRDM     = %b (esp: %b)", top_cargaRDM, exp_cargaRDM); end
            if (top_cargaAC     !== exp_cargaAC)     begin ok = 0; $display("    cargaAC      = %b (esp: %b)", top_cargaAC, exp_cargaAC); end
            if (top_cargaNZ     !== exp_cargaNZ)     begin ok = 0; $display("    cargaNZ      = %b (esp: %b)", top_cargaNZ, exp_cargaNZ); end
            if (top_cargaRI     !== exp_cargaRI)     begin ok = 0; $display("    cargaRI      = %b (esp: %b)", top_cargaRI, exp_cargaRI); end
            if (top_selUAL      !== exp_selUAL)      begin ok = 0; $display("    selUAL       = %b (esp: %b)", top_selUAL, exp_selUAL); end

            if (ok) begin
                pass_tests = pass_tests + 1;
                $display("  [PASSOU] %0s", step_name);
            end else begin
                fail_tests = fail_tests + 1;
                $display("  [FALHA ] %0s (t=%0t)", step_name, $time);
            end
        end
    endtask

    // =========================================================================
    // Procedimento Principal de Teste
    // =========================================================================
    initial begin
        $dumpfile("tb_controle.vcd");
        $dumpvars(0, tb_controle);

        total_tests = 0;
        pass_tests  = 0;
        fail_tests  = 0;

        // Inicializacao dos geradores de clock e sinais
        temp_clk     = 0;
        temp_rst_n   = 0;
        temp_goto_t0 = 0;
        temp_hlt     = 0;

        decod_op     = 4'h0;

        top_clk      = 0;
        top_rst_n    = 0;
        top_opcode   = 4'h0;
        top_flag_n   = 0;
        top_flag_z   = 0;

        clear_uc_inputs();

        $display("================================================================================");
        $display("  INICIO DOS TESTES: TEMPORIZADOR E UNIDADE DE CONTROLE (NEANDER)");
        $display("================================================================================");

        // #####################################################################
        // SECAO 1: TESTES UNITARIOS DO TEMPORIZADOR
        // #####################################################################
        $display("\n--------------------------------------------------------------------------------");
        $display(" [SECAO 1] TESTES UNITARIOS DO TEMPORIZADOR (anel de 8 bits)");
        $display("--------------------------------------------------------------------------------");

        // Teste 1.1: Reset assincrono ativo em 0
        temp_rst_n = 0;
        temp_goto_t0 = 0;
        temp_hlt = 0;
        #15; // aguarda propagacao
        check_temporizador(8'b00000001, "1.1: Reset assincrono inicial (t0 ativo)");

        // Libera reset
        @(negedge temp_clk);
        temp_rst_n = 1;

        // Teste 1.2: Deslocamento sequencial completo de t0 ate t7 e volta a t0
        @(negedge temp_clk); check_temporizador(8'b00000010, "1.2: Passo t1");
        @(negedge temp_clk); check_temporizador(8'b00000100, "1.2: Passo t2");
        @(negedge temp_clk); check_temporizador(8'b00001000, "1.2: Passo t3");
        @(negedge temp_clk); check_temporizador(8'b00010000, "1.2: Passo t4");
        @(negedge temp_clk); check_temporizador(8'b00100000, "1.2: Passo t5");
        @(negedge temp_clk); check_temporizador(8'b01000000, "1.2: Passo t6");
        @(negedge temp_clk); check_temporizador(8'b10000000, "1.2: Passo t7");
        @(negedge temp_clk); check_temporizador(8'b00000001, "1.2: Volta natural de t7 para t0");

        // Teste 1.3: Sinal goto_t0 ativado em t3 (simulando fim de NOP ou NOT)
        @(negedge temp_clk); // agora t1
        @(negedge temp_clk); // agora t2
        @(negedge temp_clk); // agora t3
        check_temporizador(8'b00001000, "1.3: Atingiu t3 antes do goto_t0");
        temp_goto_t0 = 1;
        @(negedge temp_clk);
        check_temporizador(8'b00000001, "1.3: Retorno imediato para t0 apos goto_t0 em t3");
        temp_goto_t0 = 0;

        // Teste 1.4: Sinal goto_t0 ativado em t5 (simulando fim de JMP)
        @(negedge temp_clk); // t1
        @(negedge temp_clk); // t2
        @(negedge temp_clk); // t3
        @(negedge temp_clk); // t4
        @(negedge temp_clk); // t5
        check_temporizador(8'b00100000, "1.4: Atingiu t5 antes do goto_t0");
        temp_goto_t0 = 1;
        @(negedge temp_clk);
        check_temporizador(8'b00000001, "1.4: Retorno imediato para t0 apos goto_t0 em t5");
        temp_goto_t0 = 0;

        // Teste 1.5: Congelamento com sinal HLT (simulando parada da CPU)
        @(negedge temp_clk); // t1
        @(negedge temp_clk); // t2
        check_temporizador(8'b00000100, "1.5: Congelando em t2 com HLT");
        temp_hlt = 1;
        repeat (4) begin
            @(negedge temp_clk);
            check_temporizador(8'b00000100, "1.5: Mantem t2 congelado sob HLT");
        end
        // Desativa HLT e verifica retomada para t3
        temp_hlt = 0;
        @(negedge temp_clk);
        check_temporizador(8'b00001000, "1.5: Retoma contagem para t3 apos desativar HLT");

        // Teste 1.6: Reset assincrono no meio da contagem
        @(negedge temp_clk); // t4
        check_temporizador(8'b00010000, "1.6: Contando em t4 antes do reset");
        #3;
        temp_rst_n = 0;
        #12;
        check_temporizador(8'b00000001, "1.6: Reset assincrono forcado (retorno instantaneo para t0)");
        temp_rst_n = 1;


        // #####################################################################
        // SECAO 2: TESTES DO DECODIFICADOR (0000..0110 + 1000..1010 + 1111)
        //          E CODIGOS SEM INSTRUCAO (7, 11, 12, 13, 14) EM ORDEM CRESCENTE
        // #####################################################################
        $display("\n--------------------------------------------------------------------------------");
        $display(" [SECAO 2] TESTES DO DECODIFICADOR: TODOS OS OPCODES DE 0000 A 1111 (CRESCENTE)");
        $display("--------------------------------------------------------------------------------");

        // Vetor de saida: {hlt, jz, jn, jmp, not, and, or, add, lda, sta, nop}
        decod_op = 4'b0000; #10; check_decod(11'b00000000001, "2.0: Opcode 0000 (0x0) -> NOP");
        decod_op = 4'b0001; #10; check_decod(11'b00000000010, "2.1: Opcode 0001 (0x1) -> STA");
        decod_op = 4'b0010; #10; check_decod(11'b00000000100, "2.2: Opcode 0010 (0x2) -> LDA");
        decod_op = 4'b0011; #10; check_decod(11'b00000001000, "2.3: Opcode 0011 (0x3) -> ADD");
        decod_op = 4'b0100; #10; check_decod(11'b00000010000, "2.4: Opcode 0100 (0x4) -> OR");
        decod_op = 4'b0101; #10; check_decod(11'b00000100000, "2.5: Opcode 0101 (0x5) -> AND");
        decod_op = 4'b0110; #10; check_decod(11'b00001000000, "2.6: Opcode 0110 (0x6) -> NOT");
        decod_op = 4'b0111; #10; check_decod(11'b00000000000, "2.7: Opcode 0111 (0x7) -> [SEM INSTRUCAO]");
        decod_op = 4'b1000; #10; check_decod(11'b00010000000, "2.8: Opcode 1000 (0x8) -> JMP");
        decod_op = 4'b1001; #10; check_decod(11'b00100000000, "2.9: Opcode 1001 (0x9) -> JN");
        decod_op = 4'b1010; #10; check_decod(11'b01000000000, "2.10: Opcode 1010 (0xA) -> JZ");
        decod_op = 4'b1011; #10; check_decod(11'b00000000000, "2.11: Opcode 1011 (0xB) -> [SEM INSTRUCAO]");
        decod_op = 4'b1100; #10; check_decod(11'b00000000000, "2.12: Opcode 1100 (0xC) -> [SEM INSTRUCAO]");
        decod_op = 4'b1101; #10; check_decod(11'b00000000000, "2.13: Opcode 1101 (0xD) -> [SEM INSTRUCAO]");
        decod_op = 4'b1110; #10; check_decod(11'b00000000000, "2.14: Opcode 1110 (0xE) -> [SEM INSTRUCAO]");
        decod_op = 4'b1111; #10; check_decod(11'b10000000000, "2.15: Opcode 1111 (0xF) -> HLT");


        // #####################################################################
        // SECAO 3: TESTES UNITARIOS DA UNIDADE DE CONTROLE (ORDEM CRESCENTE)
        // #####################################################################
        $display("\n--------------------------------------------------------------------------------");
        $display(" [SECAO 3] TESTES UNITARIOS DA UNIDADE DE CONTROLE (ORDEM CRESCENTE)");
        $display("--------------------------------------------------------------------------------");

        // 3.0: Ciclo de Busca (Fetch) comum (t0, t1, t2)
        // cPC, iPC, sel, cREM, rd, wr, cRDM, cAC, cNZ, cRI, gt0, uy, uadd, uand, uor, unot
        clear_uc_inputs(); set_uc_t(0); #10;
        check_uc_signals(0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.0: Fetch t0 (cargaREM=1)");

        clear_uc_inputs(); set_uc_t(1); #10;
        check_uc_signals(0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.0: Fetch t1 (read=1, incPC=1)");

        clear_uc_inputs(); set_uc_t(2); #10;
        check_uc_signals(0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, "3.0: Fetch t2 (cargaRI=1)");

        // 3.1: Instrucao 0000 (0x0) - NOP em t3
        clear_uc_inputs(); uc_nop = 1; set_uc_t(3); #10;
        check_uc_signals(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, "3.1: NOP [0000] em t3 (goto_t0=1)");

        // 3.2: Instrucao 0001 (0x1) - STA (t3..t7)
        clear_uc_inputs(); uc_sta = 1; set_uc_t(3); #10;
        check_uc_signals(0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.2: STA [0001] em t3 (cargaREM=1)");

        clear_uc_inputs(); uc_sta = 1; set_uc_t(4); #10;
        check_uc_signals(0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.2: STA [0001] em t4 (read=1, incPC=1)");

        clear_uc_inputs(); uc_sta = 1; set_uc_t(5); #10;
        check_uc_signals(0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.2: STA [0001] em t5 (cargaREM=1, sel=1)");

        clear_uc_inputs(); uc_sta = 1; set_uc_t(6); #10;
        check_uc_signals(0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.2: STA [0001] em t6 (cargaRDM=1)");

        clear_uc_inputs(); uc_sta = 1; set_uc_t(7); #10;
        check_uc_signals(0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, "3.2: STA [0001] em t7 (write=1, cAC, cNZ, gt0)");

        // 3.3: Instrucao 0010 (0x2) - LDA (t3..t7)
        clear_uc_inputs(); uc_lda = 1; set_uc_t(3); #10;
        check_uc_signals(0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.3: LDA [0010] em t3 (cargaREM=1)");

        clear_uc_inputs(); uc_lda = 1; set_uc_t(4); #10;
        check_uc_signals(0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.3: LDA [0010] em t4 (read=1, incPC=1)");

        clear_uc_inputs(); uc_lda = 1; set_uc_t(5); #10;
        check_uc_signals(0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.3: LDA [0010] em t5 (cargaREM=1, sel=1)");

        clear_uc_inputs(); uc_lda = 1; set_uc_t(6); #10;
        check_uc_signals(0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.3: LDA [0010] em t6 (read=1)");

        clear_uc_inputs(); uc_lda = 1; set_uc_t(7); #10;
        check_uc_signals(0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, "3.3: LDA [0010] em t7 (cAC, cNZ, ula_y, gt0)");

        // 3.4: Instrucao 0011 (0x3) - ADD em t7
        clear_uc_inputs(); uc_add = 1; set_uc_t(7); #10;
        check_uc_signals(0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, "3.4: ADD [0011] em t7 (cAC, cNZ, ula_add, gt0)");

        // 3.5: Instrucao 0100 (0x4) - OR em t7
        clear_uc_inputs(); uc_or_op = 1; set_uc_t(7); #10;
        check_uc_signals(0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, "3.5: OR  [0100] em t7 (cAC, cNZ, ula_or, gt0)");

        // 3.6: Instrucao 0101 (0x5) - AND em t7
        clear_uc_inputs(); uc_and_op = 1; set_uc_t(7); #10;
        check_uc_signals(0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, "3.6: AND [0101] em t7 (cAC, cNZ, ula_and, gt0)");

        // 3.7: Instrucao 0110 (0x6) - NOT em t3
        clear_uc_inputs(); uc_not_op = 1; set_uc_t(3); #10;
        check_uc_signals(0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, "3.7: NOT [0110] em t3 (cAC, cNZ, ula_not, gt0)");

        // 3.8: Instrucao 1000 (0x8) - JMP (t3..t5)
        clear_uc_inputs(); uc_jmp = 1; set_uc_t(3); #10;
        check_uc_signals(0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.8: JMP [1000] em t3 (cargaREM=1)");

        clear_uc_inputs(); uc_jmp = 1; set_uc_t(4); #10;
        check_uc_signals(0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.8: JMP [1000] em t4 (read=1, incPC=1)");

        clear_uc_inputs(); uc_jmp = 1; set_uc_t(5); #10;
        check_uc_signals(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, "3.8: JMP [1000] em t5 (cargaPC=1, goto_t0=1)");

        // 3.9: Instrucao 1001 (0x9) - JN com N=1 (salto tomado)
        clear_uc_inputs(); uc_jn = 1; uc_n_flag = 1; set_uc_t(3); #10;
        check_uc_signals(0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.9: JN [1001] (N=1) em t3 (cargaREM=1)");

        clear_uc_inputs(); uc_jn = 1; uc_n_flag = 1; set_uc_t(4); #10;
        check_uc_signals(0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.9: JN [1001] (N=1) em t4 (read=1, incPC=1)");

        clear_uc_inputs(); uc_jn = 1; uc_n_flag = 1; set_uc_t(5); #10;
        check_uc_signals(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, "3.9: JN [1001] (N=1) em t5 (cargaPC=1, goto_t0=1)");

        // 3.10: Instrucao 1001 (0x9) - JN com N=0 (salto nao tomado: pula operando e finaliza em t3)
        clear_uc_inputs(); uc_jn = 1; uc_n_flag = 0; set_uc_t(3); #10;
        check_uc_signals(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, "3.10: JN [1001] (N=0) em t3 (incPC=1, goto_t0=1)");

        // 3.11: Instrucao 1010 (0xA) - JZ com Z=1 (salto tomado)
        clear_uc_inputs(); uc_jz = 1; uc_z_flag = 1; set_uc_t(3); #10;
        check_uc_signals(0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.11: JZ [1010] (Z=1) em t3 (cargaREM=1)");

        clear_uc_inputs(); uc_jz = 1; uc_z_flag = 1; set_uc_t(4); #10;
        check_uc_signals(0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "3.11: JZ [1010] (Z=1) em t4 (read=1, incPC=1)");

        clear_uc_inputs(); uc_jz = 1; uc_z_flag = 1; set_uc_t(5); #10;
        check_uc_signals(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, "3.11: JZ [1010] (Z=1) em t5 (cargaPC=1, goto_t0=1)");

        // 3.12: Instrucao 1010 (0xA) - JZ com Z=0 (salto nao tomado: pula operando e finaliza em t3)
        clear_uc_inputs(); uc_jz = 1; uc_z_flag = 0; set_uc_t(3); #10;
        check_uc_signals(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, "3.12: JZ [1010] (Z=0) em t3 (incPC=1, goto_t0=1)");


        // #####################################################################
        // SECAO 4: TESTES INTEGRADOS (controle_top - EM ORDEM CRESCENTE DE OPCODE)
        // #####################################################################
        $display("\n--------------------------------------------------------------------------------");
        $display(" [SECAO 4] TESTES INTEGRADOS (controle_top - ORDEM CRESCENTE DE OPCODE)");
        $display("--------------------------------------------------------------------------------");

        // Reset inicial do top-level
        top_rst_n  = 0;
        top_opcode = 4'h0; // NOP
        top_flag_n = 0;
        top_flag_z = 0;
        #15;
        @(negedge top_clk);
        top_rst_n = 1;

        // 4.1: Execucao de NOP (0000 / 0x0)
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.1: NOP [0000] ciclo t0");
        @(negedge top_clk);
        check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.1: NOP [0000] ciclo t1");
        @(negedge top_clk);
        check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.1: NOP [0000] ciclo t2");
        @(negedge top_clk);
        check_top_step(8'b00001000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3'b000, "4.1: NOP [0000] ciclo t3");

        // 4.2: Execucao de STA (0001 / 0x1) - 8 ciclos
        @(negedge top_clk);
        top_opcode = 4'h1;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.2: STA [0001] t0");
        @(negedge top_clk); check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.2: STA [0001] t1");
        @(negedge top_clk); check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.2: STA [0001] t2");
        @(negedge top_clk); check_top_step(8'b00001000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.2: STA [0001] t3 (cREM)");
        @(negedge top_clk); check_top_step(8'b00010000, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.2: STA [0001] t4 (rd, incPC)");
        @(negedge top_clk); check_top_step(8'b00100000, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.2: STA [0001] t5 (sel=1, cREM)");
        @(negedge top_clk); check_top_step(8'b01000000, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 3'b000, "4.2: STA [0001] t6 (cRDM)");
        @(negedge top_clk); check_top_step(8'b10000000, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 3'b000, "4.2: STA [0001] t7 (wr, cAC, cNZ, gt0)");

        // 4.3: Execucao de LDA (0010 / 0x2) - 8 ciclos, selUAL=000
        @(negedge top_clk);
        top_opcode = 4'h2;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.3: LDA [0010] t0");
        @(negedge top_clk); check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.3: LDA [0010] t1");
        @(negedge top_clk); check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.3: LDA [0010] t2");
        @(negedge top_clk); check_top_step(8'b00001000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.3: LDA [0010] t3");
        @(negedge top_clk); check_top_step(8'b00010000, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.3: LDA [0010] t4");
        @(negedge top_clk); check_top_step(8'b00100000, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.3: LDA [0010] t5");
        @(negedge top_clk); check_top_step(8'b01000000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.3: LDA [0010] t6 (rd)");
        @(negedge top_clk); check_top_step(8'b10000000, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 3'b000, "4.3: LDA [0010] t7 (cAC, cNZ, gt0, selUAL=000)");

        // 4.4: Execucao de ADD (0011 / 0x3) - selUAL=001
        @(negedge top_clk);
        top_opcode = 4'h3;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.4: ADD [0011] t0");
        @(negedge top_clk); // t1
        @(negedge top_clk); // t2
        @(negedge top_clk); // t3
        @(negedge top_clk); // t4
        @(negedge top_clk); // t5
        @(negedge top_clk); // t6
        @(negedge top_clk); // t7
        check_top_step(8'b10000000, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 3'b001, "4.4: ADD [0011] t7 (selUAL=001)");

        // 4.5: Execucao de OR (0100 / 0x4) - selUAL=011
        @(negedge top_clk);
        top_opcode = 4'h4;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.5: OR  [0100] t0");
        @(negedge top_clk); // t1
        @(negedge top_clk); // t2
        @(negedge top_clk); // t3
        @(negedge top_clk); // t4
        @(negedge top_clk); // t5
        @(negedge top_clk); // t6
        @(negedge top_clk); // t7
        check_top_step(8'b10000000, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 3'b011, "4.5: OR  [0100] t7 (selUAL=011)");

        // 4.6: Execucao de AND (0101 / 0x5) - selUAL=010
        @(negedge top_clk);
        top_opcode = 4'h5;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.6: AND [0101] t0");
        @(negedge top_clk); // t1
        @(negedge top_clk); // t2
        @(negedge top_clk); // t3
        @(negedge top_clk); // t4
        @(negedge top_clk); // t5
        @(negedge top_clk); // t6
        @(negedge top_clk); // t7
        check_top_step(8'b10000000, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 3'b010, "4.6: AND [0101] t7 (selUAL=010)");

        // 4.7: Execucao de NOT (0110 / 0x6) - selUAL=100
        @(negedge top_clk);
        top_opcode = 4'h6;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.7: NOT [0110] ciclo t0");
        @(negedge top_clk);
        check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.7: NOT [0110] ciclo t1");
        @(negedge top_clk);
        check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.7: NOT [0110] ciclo t2");
        @(negedge top_clk);
        check_top_step(8'b00001000, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 3'b100, "4.7: NOT [0110] ciclo t3");

        // 4.8: Execucao de JMP (1000 / 0x8) - 6 ciclos
        @(negedge top_clk);
        top_opcode = 4'h8;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.8: JMP [1000] t0");
        @(negedge top_clk); check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.8: JMP [1000] t1");
        @(negedge top_clk); check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.8: JMP [1000] t2");
        @(negedge top_clk); check_top_step(8'b00001000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.8: JMP [1000] t3 (cREM)");
        @(negedge top_clk); check_top_step(8'b00010000, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.8: JMP [1000] t4 (rd, incPC)");
        @(negedge top_clk); check_top_step(8'b00100000, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3'b000, "4.8: JMP [1000] t5 (cargaPC=1, goto_t0=1)");

        // 4.9: Execucao de JN (1001 / 0x9) com flag_n = 1 (salto tomado)
        @(negedge top_clk);
        top_opcode = 4'h9;
        top_flag_n = 1;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.9: JN [1001] (N=1) t0");
        @(negedge top_clk); check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.9: JN [1001] (N=1) t1");
        @(negedge top_clk); check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.9: JN [1001] (N=1) t2");
        @(negedge top_clk); check_top_step(8'b00001000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.9: JN [1001] (N=1) t3 (cREM)");
        @(negedge top_clk); check_top_step(8'b00010000, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.9: JN [1001] (N=1) t4 (rd, incPC)");
        @(negedge top_clk); check_top_step(8'b00100000, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3'b000, "4.9: JN [1001] (N=1) t5 (cargaPC=1, goto_t0=1)");

        // 4.10: Execucao de JN (1001 / 0x9) com flag_n = 0 (salto nao tomado - encerra em t3 pulando operando)
        @(negedge top_clk);
        top_opcode = 4'h9;
        top_flag_n = 0;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.10: JN [1001] (N=0) t0");
        @(negedge top_clk); check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.10: JN [1001] (N=0) t1");
        @(negedge top_clk); check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.10: JN [1001] (N=0) t2");
        @(negedge top_clk); check_top_step(8'b00001000, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 3'b000, "4.10: JN [1001] (N=0) t3 (incPC=1, goto_t0=1)");

        // 4.11: Execucao de JZ (1010 / 0xA) com flag_z = 1 (salto tomado)
        @(negedge top_clk);
        top_opcode = 4'hA;
        top_flag_z = 1;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.11: JZ [1010] (Z=1) t0");
        @(negedge top_clk); check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.11: JZ [1010] (Z=1) t1");
        @(negedge top_clk); check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.11: JZ [1010] (Z=1) t2");
        @(negedge top_clk); check_top_step(8'b00001000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.11: JZ [1010] (Z=1) t3 (cREM)");
        @(negedge top_clk); check_top_step(8'b00010000, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.11: JZ [1010] (Z=1) t4 (rd, incPC)");
        @(negedge top_clk); check_top_step(8'b00100000, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3'b000, "4.11: JZ [1010] (Z=1) t5 (cargaPC=1, goto_t0=1)");

        // 4.12: Execucao de JZ (1010 / 0xA) com flag_z = 0 (salto nao tomado)
        @(negedge top_clk);
        top_opcode = 4'hA;
        top_flag_z = 0;
        #2;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.12: JZ [1010] (Z=0) t0");
        @(negedge top_clk); check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.12: JZ [1010] (Z=0) t1");
        @(negedge top_clk); check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.12: JZ [1010] (Z=0) t2");
        @(negedge top_clk); check_top_step(8'b00001000, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 3'b000, "4.12: JZ [1010] (Z=0) t3 (incPC=1, goto_t0=1)");

        // 4.13: Execucao de HLT (1111 / 0xF) - congela a maquina
        @(negedge top_clk);
        top_opcode = 4'h0;
        check_top_step(8'b00000001, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 3'b000, "4.13: HLT [1111] busca t0");
        @(negedge top_clk);
        check_top_step(8'b00000010, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3'b000, "4.13: HLT [1111] busca t1");
        @(negedge top_clk);
        check_top_step(8'b00000100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3'b000, "4.13: HLT [1111] busca t2 (cargaRI)");
        top_opcode = 4'hF; // RI atualizado com HLT!
        #5;

        $display("  Aplicando HLT (opcode 1111 / 0xF) no top-level...");
        repeat (5) begin
            @(negedge top_clk);
            total_tests = total_tests + 1;
            if (top_estado_t === 8'b00000100) begin
                pass_tests = pass_tests + 1;
                $display("  [PASSOU] 4.13: Top-level paralisado em t2 sob HLT [1111]");
            end else begin
                fail_tests = fail_tests + 1;
                $display("  [FALHA ] 4.13: Top-level nao congelou sob HLT! estado_t=%b", top_estado_t);
            end
        end

        // #####################################################################
        // RELATORIO FINAL DE EXECUCAO
        // #####################################################################
        $display("\n================================================================================");
        $display("  RELATORIO FINAL DOS TESTES");
        $display("================================================================================");
        $display("  Total de Verificacoes : %0d", total_tests);
        $display("  Passaram              : %0d", pass_tests);
        $display("  Falharam              : %0d", fail_tests);
        if (fail_tests == 0) begin
            $display("\n  >>> SUCESSO: TODOS OS TESTES PASSARAM! DESIGN VALIDADO! <<<\n");
        end else begin
            $display("\n  >>> ATENCAO: FORAM DETECTADAS %0d FALHAS NOS TESTES! <<<\n", fail_tests);
        end
        $display("================================================================================\n");

        $finish;
    end

endmodule
