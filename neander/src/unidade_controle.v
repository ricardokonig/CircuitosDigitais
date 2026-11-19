`timescale 1ns/1ns

/*
  inst_dado = sta+lda+add+or+and
  insta_end2 = sta+lda+add+or+and+jmp+jn+jz
*/

// logica combinacional de controle: gera os sinais do Neander conforme o passo t0..t7 e a instrucao
module unidade_controle (
    // pulsos de tempo do temporizador
    input  wire t0, t1, t2, t3, t4, t5, t6, t7,

    // instrucoes decodificadas
    input  wire nop, sta, lda, add, or_op, and_op, not_op, jmp, jn, jz,

    // flags de condicao
    input  wire n_flag,
    input  wire z_flag,

    // sinais pro datapath
    output wire cargaPC,
    output wire incrementaPC,
    output wire sel,          // 0 = PC, 1 = RDM
    output wire cargaREM,
    output wire read,
    output wire write,
    output wire cargaRDM,
    output wire cargaAC,
    output wire cargaNZ,
    output wire cargaRI,
    output wire goto_t0,      // reinicia o temporizador no t0

    // sinais individuais da ULA
    output wire ula_y,
    output wire ula_add,
    output wire ula_and,
    output wire ula_or,
    output wire ula_not
);

    // verificação jmp
    wire jn_tomado, jz_tomado;
    and #1 g_jnt (jn_tomado, jn, n_flag);
    and #1 g_jzt (jz_tomado, jz, z_flag);

    // agrupamento 1: instrucoes de 2 bytes que precisam ler o endereco do operando em t3
    wire inst_end2;
    or #1 g_end (inst_end2, sta, lda, add, or_op, and_op, jmp, jn_tomado, jz_tomado);

    // agrupamento 2: instrucoes que acessam dado na memoria em t5
    wire inst_dado;
    or #1 g_dado (inst_dado, sta, lda, add, or_op, and_op);

    // agrupamento 3: instrucoes da ULA que leem o dado e gravam no AC em t6
    wire inst_ula_mem;
    or #1 g_ulamem (inst_ula_mem, lda, add, or_op, and_op);

    wire jump_valido;
    or  #1 g_jmpval (jump_valido, jmp, jn_tomado, jz_tomado);

    // cargaREM: pega endereco em t0 (opcode), em t3 (operando) e em t5 (dado)
    wire rem_t3, rem_t5;
    and #1 g_rem3 (rem_t3, t3, inst_end2);
    and #1 g_rem5 (rem_t5, t5, inst_dado);
    or  #1 g_rem  (cargaREM, t0, rem_t3, rem_t5);

    // sel: escolhe no MUX entre PC (0) e RDM (1). So vai pra 1 em t5 pra buscar o dado
    and #1 g_sel (sel, t5, inst_dado);

    // read: le memoria em t1 (opcode), t4 (operando) e t6 (dado)
    wire rd_t4, rd_t6;
    and #1 g_rd4 (rd_t4, t4, inst_end2);
    and #1 g_rd6 (rd_t6, t6, inst_ula_mem);
    or  #1 g_rd  (read, t1, rd_t4, rd_t6);

    // write: so a instrucao STA grava na memoria (no ciclo t6)
    and #1 g_wr (write, t7, sta);

    // jn e jz com flags n e z desativados
    wire t3_inpc, jnnl_jzzl, jnnl, jzzl;
    and #1 g_jnnl (jnnl, jn, ~n_flag);
    and #1 g_jzzl (jzzl, jz, ~z_flag);
    or #1 g_inpc1 (jnnl_jzzl, jnnl, jzzl);
    and #1 g_t3_j (t3_inpc, t3, jnnl_jzzl);

    // incrementaPC: avanca o PC logo apos ler o opcode (t1) e o operando (t4)
    or  #1 g_incpc (incrementaPC, t1, rd_t4, t3_inpc);

    // cargaPC: se o salto for valido, carrega o novo endereco no PC em t5
    and #1 g_cpc (cargaPC, t5, jump_valido);

    // cargaRI: grava o opcode no registrador de instrucao em t2
    buf #1 g_cri (cargaRI, t2);

    // cargaRDM: le dado pro RDM (ou copia AC pro RDM em t5 pra gravar no STA)
    and  #1 g_crdm (cargaRDM, t6, sta);

    // act6:
    wire ac_t6;
    and #1 g_ct_t6 (ac_t6, t7, inst_dado);

    // cargaAC: atualiza o acumulador em t3 no NOT, ou em t6 nas operacoes com memoria
    wire ac_t3_not;
    and #1 g_ac_not (ac_t3_not, t3, not_op);
    or  #1 g_cac (cargaAC, ac_t3_not, ac_t6);

    // cargaNZ: sempre que mexe no AC, atualiza as flags de condicao
    buf #1 g_cnz (cargaNZ, cargaAC);

    // comandos individuais pra ULA
    and #1 g_uy  (ula_y,   t7, lda);
    and #1 g_uadd(ula_add, t7, add);
    and #1 g_uand(ula_and, t7, and_op);
    and #1 g_uor (ula_or,  t7, or_op);
    buf #1 g_unot(ula_not, ac_t3_not);

    // goto_t0: diz quando a instrucao acabou e o temporizador deve voltar pro t0
    // NOP e NOT acabam em t3; saltos acabam em t5; operacoes com memoria acabam em t6
    wire fim_t3_nop, fim_t3, fim_t5, fim_t7, fim_t3_jnnljzzl;
    and #1 g_f3nop (fim_t3_nop, t3, nop);
    and #1 g_t3_jnnl_jzzl (fim_t3_jnnljzzl, t3, jnnl_jzzl);
    or  #1 g_f3 (fim_t3, fim_t3_nop, ac_t3_not, fim_t3_jnnljzzl);

    wire inst_jump_qualquer;
    or  #1 g_jmpqualq (inst_jump_qualquer, jmp, jn_tomado, jz_tomado);
    and #1 g_f5 (fim_t5, t5, inst_jump_qualquer);

    and #1 g_f6 (fim_t7, t7, inst_dado);

    or  #1 g_gt0 (goto_t0, fim_t3, fim_t5, fim_t7);

endmodule
