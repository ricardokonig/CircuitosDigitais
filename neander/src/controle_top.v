`timescale 1ns/1ns

// modulo top-level: junta temporizador, decodificador e unidade de controle
module controle_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] opcode,  // 4 bits do RI[7:4]
    input  wire       flag_n,  // flag negativo
    input  wire       flag_z,  // flag zero

    // sinais pro datapath
    output wire       cargaPC,
    output wire       incrementaPC,
    output wire       sel,     // 0 = PC, 1 = RDM
    output wire       cargaREM,
    output wire       read,
    output wire       write,
    output wire       cargaRDM,
    output wire       cargaAC,
    output wire       cargaNZ,
    output wire       cargaRI,
    output wire       goto_t0,

    // sinais pra ULA
    output wire       ula_y,
    output wire       ula_add,
    output wire       ula_and,
    output wire       ula_or,
    output wire       ula_not,
    output wire [2:0] selUAL,

    // monitoramento dos passos t0..t7
    output wire [7:0] estado_t
);

    // barramento one-hot com os 8 passos de tempo (t0 e o bit 0)
    wire t0, t1, t2, t3, t4, t5, t6, t7;
    assign estado_t = {t7, t6, t5, t4, t3, t2, t1, t0};

    // fios das instrucoes decodificadas
    wire nop, sta, lda, add, or_op, and_op, not_op, jmp, jn, jz, hlt;

    // 1. temporizador em anel
    temporizador u_temp (
        .clk(clk),
        .rst_n(rst_n),
        .goto_t0(goto_t0),
        .hlt(hlt),
        .t0(t0), .t1(t1), .t2(t2), .t3(t3),
        .t4(t4), .t5(t5), .t6(t6), .t7(t7)
    );

    // 2. decodificador do opcode
    decod_inst u_decod (
        .op(opcode),
        .nop(nop),
        .sta(sta),
        .lda(lda),
        .add(add),
        .or_op(or_op),
        .and_op(and_op),
        .not_op(not_op),
        .jmp(jmp),
        .jn(jn),
        .jz(jz),
        .hlt(hlt)
    );

    // 3. unidade de controle combinacional
    unidade_controle u_uc (
        .t0(t0), .t1(t1), .t2(t2), .t3(t3),
        .t4(t4), .t5(t5), .t6(t6), .t7(t7),
        .nop(nop), .sta(sta), .lda(lda), .add(add),
        .or_op(or_op), .and_op(and_op), .not_op(not_op),
        .jmp(jmp), .jn(jn), .jz(jz),
        .n_flag(flag_n),
        .z_flag(flag_z),
        .cargaPC(cargaPC),
        .incrementaPC(incrementaPC),
        .sel(sel),
        .cargaREM(cargaREM),
        .read(read),
        .write(write),
        .cargaRDM(cargaRDM),
        .cargaAC(cargaAC),
        .cargaNZ(cargaNZ),
        .cargaRI(cargaRI),
        .goto_t0(goto_t0),
        .ula_y(ula_y),
        .ula_add(ula_add),
        .ula_and(ula_and),
        .ula_or(ula_or),
        .ula_not(ula_not)
    );

    // 4. codificador pra gerar o seletor da ULA (selUAL de 3 bits)
    codificador_ula u_cod_ula (
        .ula_y(ula_y),
        .ula_add(ula_add),
        .ula_and(ula_and),
        .ula_or(ula_or),
        .ula_not(ula_not),
        .selUAL(selUAL)
    );

endmodule
