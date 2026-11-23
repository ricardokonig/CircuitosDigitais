# Diagnóstico e Mapeamento: Projeto Neander Completo com Memória

Este documento consolida o estado atual do **Projeto Final: Neander Completo com Memória** (INF01086 - Circuitos Digitais / UFRGS - Prof. Mateus Grellert).

---

## 1. Visão Geral dos Requisitos do Projeto

O objetivo do projeto é projetar, simular e prototipar em FPGA (Altera Cyclone III `EP3C16F484C6` - Placa DE0) um processador **Neander Completo** de 8 bits com:
- **Unidade de Controle:** Baseada em expressões lógicas combinacionais hardcoded (sem uso explícito de FSM).
- **Memória:** ROM/RAM de 256 posições de 8 bits inicializada com programa de teste completo.
- **Temporizador:** Gerador de passos $t_0$ a $t_7$ com entradas de reset assíncrono, reset síncrono (`goto_t0`) e parada (`HLT`).
- **Interface FPGA:**
  - 4 Displays de 7 segmentos estruturais: 2 para `PC` (HEX3 e HEX2) e 2 para `AC` (HEX1 e HEX0).
  - LEDs: `LEDG0` (Flag N), `LEDG1` (Flag Z), `LEDG5` (HLT).
  - Controle de Clock / Execução: `SW0` (Modo RUN contínuo vs Modo DEBUG passo a passo) e `BUTTON1` (Clock manual / *step up* no modo DEBUG).
  - Reset geral: `BUTTON0`.
- **Entregáveis no Moodle:** Arquivo `cartao1_cartao2.zip` contendo o projeto Quartus completo e capturas de tela da simulação em forma de onda.

---

## 2. Inventário dos Arquivos no Diretório `neander/`

### 2.1. Código-Fonte Verilog (`neander/src/`) e Testes (`neander/tb/`)

| Arquivo | Tipo / Função | Restrição | Status |
| :--- | :--- | :---: | :---: |
| `src/ffd.v` | Flip-Flop D com reset assíncrono ativo em 0 (`rst_n`). Bloco base para registradores e temporizador. | Estrutural | ✅ **Concluído** |
| `src/decod_inst.v` (ID 1) | Decodificador estrutural de 4 bits (opcode `RI[7:4]`) gerando as 11 instruções do Neander com portas `not` e `and`. | Estrutural | ✅ **Concluído** |
| `src/codificador_ula.v` (ID 2) | Codificador estrutural que converte os 5 comandos da ULA no seletor de 3 bits `selUAL[2:0]`. | Estrutural | ✅ **Concluído** |
| `src/mux2x1_8b.v` / `src/mux_rem.v` (ID 3) | Multiplexador 2:1 de 8 bits para o REM (`sel = 0` seleciona `PC`, `sel = 1` seleciona `RDM`). | Combinacional | ✅ **Concluído** |
| `src/ula.v` (ID 4) | ULA combinacional de 8 bits com operações Y, ADD, AND, OR, NOT e flags N e Z. | Combinacional | ✅ **Concluído** |
| `src/divisor_clock.v` (ID 5) | Divisor de clock estrutural em cascata de 24 flip-flops D (50 MHz -> ~2.98 Hz). | Estrutural | ✅ **Concluído** |
| `src/run_step_mode.v` (ID 6) | Seletor de modo RUN (clock contínuo) vs STEP (avanço manual via BUTTON1). | Estrutural | ✅ **Concluído** |
| `src/pc.v` (ID 8) | Program Counter de 8 bits estrutural em cascata Ripple Carry com fatias `pc_slice`, `ffd.v`, `cargaPC` e `incrementaPC`. | Estrutural | ✅ **Concluído** |
| `src/reg8.v` (ID 7) | Registrador estrutural genérico de 8 bits com carga síncrona habilitada e reset assíncrono (`ffd.v`). | Estrutural | ✅ **Concluído** |
| `src/reg_ac.v` | Registrador Acumulador (AC) de 8 bits habilitado por `cargaAC`. | Estrutural | ✅ **Concluído** |
| `src/reg_rdm.v` | Registrador de Dados da Memória (RDM) de 8 bits habilitado por `cargaRDM`. | Estrutural | ✅ **Concluído** |
| `src/reg_rem.v` | Registrador de Endereço da Memória (REM) de 8 bits habilitado por `cargaREM`. | Estrutural | ✅ **Concluído** |
| `src/reg_ri.v` | Registrador de Instrução (RI) de 8 bits habilitado por `cargaRI`. | Estrutural | ✅ **Concluído** |
| `src/reg_flags.v` (ID 9) | Registrador estrutural de Flags (N, Z) de 2 bits habilitado por `cargaNZ` e reset assíncrono. | Estrutural | ✅ **Concluído** |
| `src/temporizador.v` (ID 10) | Contador em anel estrutural de 8 bits ($t_0 \dots t_7$) com entradas de reset assíncrono, `goto_t0` e `hlt`. | Estrutural | ✅ **Concluído** |
| `src/unidade_controle.v` (ID 11) | Lógica combinacional hardcoded implementando as 16 equações booleanas da Fig. 2 do PDF. | Combinacional | ✅ **Concluído** |
| `src/controle_top.v` | Módulo top-level integrando ID 1, ID 2, ID 10 e ID 11. | Estrutural | ✅ **Concluído** |
| `src/bcd_7seg.v` (ID 12) | Decodificador Hexadecimal para 7 segmentos estrutural (decodificador 4:16 de mintermos + matriz OR ativa em 0). | Estrutural | ✅ **Concluído** |
| `src/memoria.v` | Memória de 256 bytes inicializada com o programa de testes Neander completo. | RAM/ROM | ✅ **Concluído** |
| `src/neander_top.v` | Módulo Top-Level integrando controle, datapath, memória, divisor, run/step e 4 displays 7-seg. | Top-Level | ✅ **Concluído** |
| `tb/tb_controle.v` / `.vcd` | Testbench com **130 verificações (130 aprovadas, 0 falhas)** validando Temporizador e UC. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_mux_rem.v` / `.vcd` | Testbench com **32 verificações (32 aprovadas, 0 falhas)** validando o MUX do REM. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_ula.v` / `.vcd` | Testbench com **15 verificações (15 aprovadas, 0 falhas)** validando a ULA e flags N/Z. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_divisor.v` / `.vcd` | Testbench com **19 verificações (19 aprovadas, 0 falhas)** validando o divisor de clock. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_run_step.v` / `.vcd` | Testbench com **15 verificações (15 aprovadas, 0 falhas)** validando o modo RUN/STEP. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_pc.v` / `.vcd` | Testbench com **29 verificações (29 aprovadas, 0 falhas)** validando o PC completo. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_registradores.v` / `.vcd` | Testbench com **48 verificações (48 aprovadas, 0 falhas)** validando reg8, AC, RDM, REM e RI. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_flags.v` / `.vcd` | Testbench com **10 verificações (10 aprovadas, 0 falhas)** validando o Registrador de Flags. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_bcd_7seg.v` / `.vcd` | Testbench com **16 verificações (16 aprovadas, 0 falhas)** validando todos os dígitos 0-F no display 7-seg. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_memoria.v` / `.vcd` | Testbench com **18 verificações (18 aprovadas, 0 falhas)** validando leitura e escrita na memória. | Testbench | ✅ **Concluído e Validado** |
| `tb/tb_neander.v` / `.vcd` | Testbench de integração com **14 verificações (14 aprovadas, 0 falhas)** validando execução end-to-end. | Testbench | ✅ **Concluído e Validado** |

---

## 3. Matriz de Conformidade Atualizada (100% Concluída)

| ID | Componente Exigido | Restrição | Status Atual | Arquivo / Diagnóstico |
| :---: | :--- | :---: | :---: | :--- |
| **1** | **Decodificador de Instruções** | **Estrutural** | ✅ **Pronto** | `decod_inst.v` (estrutural com portas lógicas primitivas, testado 16/16 opcodes). |
| **2** | **Codificador ULA** | **Estrutural** | ✅ **Pronto** | `codificador_ula.v` (estrutural com `or` e `buf`, gera `selUAL[2:0]`). |
| **3** | **MUX do REM** | - | ✅ **Pronto** | `mux2x1_8b.v` / `mux_rem.v` (seleciona entre `PC` e `RDM` via sinal `sel`, testado em `tb_mux_rem.v`). |
| **4** | **ULA Neander (8 bits)** | - | ✅ **Pronto** | ULA combinacional de 8 bits (Y, ADD, AND, OR, NOT e flags N e Z), testada e validada em `tb_ula.v`. |
| **5** | **Divisor de Clock** | **Estrutural** | ✅ **Pronto** | `divisor_clock.v` (cascata estrutural de 24 flip-flops D `ffd.v`, 50 MHz -> ~2.98 Hz, validado em `tb_divisor.v`). |
| **6** | **Run/Step Mode** | **Estrutural** | ✅ **Pronto** | `run_step_mode.v` (comutador estrutural RUN via clk divisor vs STEP via BUTTON1, validado em `tb_run_step.v`). |
| **7** | **Registradores AC, RDM, REM, RI** | **Estrutural** | ✅ **Pronto** | `reg8.v` (módulo estrutural genérico com `reg1b`, `ffd.v` e MUX de carga), com wrappers `reg_ac.v`, `reg_rdm.v`, `reg_rem.v` e `reg_ri.v`. Validado em `tb_registradores.v`. |
| **8** | **PC (Program Counter)** | **Estrutural** | ✅ **Pronto** | `pc.v` (estrutural Ripple Carry com fatias `pc_slice`, portas lógicas e `ffd.v`, validado em `tb_pc.v`). |
| **9** | **Registrador de Flags (N, Z)** | **Estrutural** | ✅ **Pronto** | `reg_flags.v` (registrador estrutural de 2 bits com `reg1b`, validado em `tb_flags.v`). |
| **10** | **Temporizador ($t_0 \dots t_7$)** | **Estrutural** | ✅ **Pronto** | `temporizador.v` (anel estrutural com `ffd`, reset assíncrono, `goto_t0` e `hlt`, testado e validado). |
| **11** | **Unidade de Controle (UC)** | - | ✅ **Pronto** | `unidade_controle.v` (16 expressões booleanas hardcoded conforme Fig. 2 do PDF, validado em `tb_controle.v`). |
| **12** | **Decodificador BCD-7seg (Hex)** | **Estrutural** | ✅ **Pronto** | `bcd_7seg.v` (matriz estrutural 4:16 e portas OR ativas em 0, validado em `tb_bcd_7seg.v`). |
| **-** | **Memória RAM/ROM Neander** | - | ✅ **Pronto** | `memoria.v` (256 bytes com programa de teste pré-carregado, validado em `tb_memoria.v`). |
| **-** | **Top-Level Neander Geral** | - | ✅ **Pronto** | `neander_top.v` conectando todos os blocos com pinagem mapeada para Altera DE0. |
| **-** | **Simulação Geral do Neander** | - | ✅ **Pronto** | `tb_neander.v` validando todo o ciclo de busca e execução de ponta a ponta. |

---

## 4. Resumo de Execução da Suíte de Testes (`make test`)

Todos os 11 testbenches do projeto são executados automaticamente através do Makefile (`make test`):
1. `tb/tb_bcd_7seg.v`: 16/16 verificações aprovadas.
2. `tb/tb_controle.v`: 130/130 verificações aprovadas.
3. `tb/tb_divisor.v`: 19/19 verificações aprovadas.
4. `tb/tb_flags.v`: 10/10 verificações aprovadas.
5. `tb/tb_memoria.v`: 18/18 verificações aprovadas.
6. `tb/tb_mux_rem.v`: 32/32 verificações aprovadas.
7. `tb/tb_neander.v`: 14/14 verificações aprovadas.
8. `tb/tb_pc.v`: 29/29 verificações aprovadas.
9. `tb/tb_registradores.v`: 48/48 verificações aprovadas.
10. `tb/tb_run_step.v`: 15/15 verificações aprovadas.
11. `tb/tb_ula.v`: 15/15 verificações aprovadas.

**Total Geral:** **346 verificações aprovadas**, **0 falhas**.
