# Diagnóstico e Mapeamento: Projeto Neander Completo com Memória

Este documento consolida o estado atual do **Projeto Final: Neander Completo com Memória** (INF01086 - Circuitos Digitais / UFRGS - Prof. Mateus Grellert), atualizado após a análise dos módulos recém-adicionados no diretório base.

---

## 1. Visão Geral dos Requisitos do Projeto

O objetivo do projeto é projetar, simular e prototipar em FPGA (Altera Cyclone III `EP3C16F484C6` - Placa DE0) um processador **Neander Completo** de 8 bits com:
- **Unidade de Controle:** Baseada em expressões lógicas combinacionais hardcoded (sem uso explícito de FSM).
- **Memória:** ROM de 256 posições de 8 bits (baseada no VHDL disponibilizado pelo professor no Gist) ou RAM (desafio opcional).
- **Temporizador:** Gerador de passos $t_0$ a $t_7$ com entradas de reset assíncrono, reset síncrono (`goto_t0`) e parada (`HLT`).
- **Interface FPGA:**
  - 4 Displays de 7 segmentos: 2 para `PC` (HEX3 e HEX2) e 2 para `AC` (HEX1 e HEX0).
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
| `src/temporizador.v` (ID 10) | Contador em anel estrutural de 8 bits ($t_0 \dots t_7$) com entradas de reset assíncrono, `goto_t0` e `hlt`. | Estrutural | ✅ **Concluído** |
| `src/unidade_controle.v` (ID 11) | Lógica combinacional hardcoded implementando as 16 equações booleanas da Fig. 2 do PDF. | Combinacional | ✅ **Concluído** |
| `src/controle_top.v` | Módulo top-level integrando ID 1, ID 2, ID 10 e ID 11. | Estrutural | ✅ **Concluído** |
| `tb/tb_controle.v` / `.vcd` | Testbench exaustivo com **130 verificações (130 aprovadas, 0 falhas)** e arquivo de formas de onda gerado. | Testbench | ✅ **Concluído e Validado** |
| `docs/OPCODES.md` | Documentação técnica completa dos opcodes, ciclos de temporização e sinais de controle. | Documentação | ✅ **Concluído** |
| `docs/GUIA_TESTES_E_SIMULACAO.md` | Guia completo de simulação, execução via Makefile/iverilog e inclusão de novos testbenches. | Documentação | ✅ **Concluído** |

### 2.2. Arquivos Existentes nos Laboratórios Anteriores (`CircuitosDigitais/`)

| Caminho / Arquivo | Conteúdo | Aproveitamento no Neander |
| :--- | :--- | :--- |
| `CircuitosDigitais/LAB8.zip` | `contador_8b.v`, `blocos_base.v`, `ClockDiv.v`, `BCD_7seg.v`, `top_level.qsf` | Base quase pronta para o **PC (ID 8)**, decodificador de display e pinagem da DE0. |
| `CircuitosDigitais/lab5.zip` | Divisor de clock em esquemático `.bdf` com DFFs | Referência para divisor estrutural de clock. |
| `CircuitosDigitais/LAB3/` | Decodificador 2 para 4 com enable | Referência didática. |

---

## 3. Matriz de Conformidade Atualizada: O Que Tem vs. O Que Falta

Com a adição dos novos arquivos, **toda a Unidade de Controle e Temporização do Neander está 100% pronta e testada**. O foco restante agora é o **Datapath**, a **Memória**, os **Periféricos da FPGA** e a **Integração Top-Level**.

| ID | Componente Exigido | Restrição | Status Atual | Arquivo / Diagnóstico |
| :---: | :--- | :---: | :---: | :--- |
| **1** | **Decodificador de Instruções** | **Estrutural** | ✅ **Pronto** | `decod_inst.v` (estrutural com portas lógicas primitivas, testado 16/16 opcodes). |
| **2** | **Codificador ULA** | **Estrutural** | ✅ **Pronto** | `codificador_ula.v` (estrutural com `or` e `buf`, gera `selUAL[2:0]`). |
| **3** | **MUX do REM** | - | ❌ **Falta** | MUX 2:1 de 8 bits para selecionar entre `PC` e `RDM` com base no sinal `sel`. |
| **4** | **ULA Neander (8 bits)** | - | ❌ **Falta** | ULA de 8 bits executando Y (000), ADD (001), AND (010), OR (011) e NOT (100), com geração das flags N e Z. |
| **5** | **Divisor de Clock** | **Estrutural** | ⚠️ **Parcial** | `ClockDiv.v` no LAB8 é comportamental. Precisa ser estrutural (cascata de flip-flops D como no LAB5) se exigido à risca. |
| **6** | **Run/Step Mode** | - | ❌ **Falta** | Circuito de controle para alternar entre clock do divisor (RUN) e avanço manual por botão `BUTTON1` (DEBUG). |
| **7** | **Registradores AC, RDM, REM** | - | ❌ **Falta** | Registradores de 8 bits com carga síncrona habilitada e reset assíncrono (usar células `ffd.v`). |
| **8** | **PC (Program Counter)** | **Estrutural** | ⚠️ **Parcial** | O `contador_8b.v` do LAB8 já tem estrutura de fatias de bit; precisa trocar os FFs internos por `ffd.v` (com reset assíncrono) e mapear `cargaPC` e `incrementaPC`. |
| **9** | **Registrador de Flags (N, Z)** | - | ❌ **Falta** | Registrador de 2 bits com habilitação de carga (`cargaNZ`) e reset assíncrono. |
| **10** | **Temporizador ($t_0 \dots t_7$)** | **Estrutural** | ✅ **Pronto** | `temporizador.v` (anel estrutural com `ffd`, reset assíncrono, `goto_t0` e `hlt`, testado e validado). |
| **11** | **Unidade de Controle (UC)** | - | ✅ **Pronto** | `unidade_controle.v` (16 expressões booleanas hardcoded conforme Fig. 2 do PDF, validado em `tb_controle.v`). |
| **12** | **Decodificador BCD-7seg (Hex)** | **Estrutural** | ⚠️ **Parcial** | `BCD_7seg.v` do LAB8 é comportamental (`case`). Converter para estrutural para atender à restrição da Tabela I. |
| **-** | **Memória ROM Neander** | VHDL | ❌ **Falta** | Baixar o `rom_neander.vhd` disponibilizado pelo professor no [Gist oficial](https://gist.github.com/grellert/19b6192becacb7c1a0d9f36e2b2a71c9#file-rom_neander-vhd) e instanciar no projeto. |
| **-** | **Top-Level Neander Geral** | - | ❌ **Falta** | Criar módulo integrador (`neander_top.v` ou `.bdf`) conectando `controle_top.v`, Datapath, Memória, Displays e Clock. |
| **-** | **Simulação Geral do Neander** | - | ❌ **Falta** | Simular a execução de um programa Neander completo em forma de onda (`.vwf` / testbench). |

---

## 4. O Que Resta Fazer (Plano de Ação)

Com o bloco de controle totalmente finalizado e verificado, o trabalho restante divide-se em 3 frentes:

### Frente 1: Módulos do Datapath
1. **`reg8.v` (Registrador de 8 bits):** Implementar módulo genérico de 8 bits com `enable` e reset assíncrono usando `ffd.v`. Será instanciado 4 vezes: `AC`, `RDM`, `REM` e `RI`.
2. **`reg_flags.v` (Registrador de Flags):** Implementar módulo de 2 bits com `enable` (`cargaNZ`) e reset assíncrono para as flags N e Z.
3. **`mux2x1_8b.v`:** Multiplexador 2 para 1 de 8 bits para o REM (`sel = 0` seleciona PC, `sel = 1` seleciona RDM).
4. **`pc_8b.v`:** Adaptar `contador_8b.v` do LAB8, integrando o `ffd.v` para garantir reset assíncrono e controle por `cargaPC` e `incrementaPC`.
5. **`ula_8b.v`:** Implementar a ULA de 8 bits correspondente ao `selUAL[2:0]`:
   - `3'b000`: $Y$ (barramento do RDM)
   - `3'b001`: $ADD$ ($AC + RDM$)
   - `3'b010`: $AND$ ($AC \land RDM$)
   - `3'b011`: $OR$ ($AC \lor RDM$)
   - `3'b100`: $NOT$ ($\sim AC$)
   - Saídas de status: $N = S[7]$ e $Z = \sim(\lvert S)$.

### Frente 2: Memória e Interface FPGA
1. **Memória ROM:** Incluir o arquivo `rom_neander.vhd` da disciplina com os 256 bytes e programa teste.
2. **Divisor de Clock Estrutural:** Converter o divisor para flip-flops D em cascata ou contadores estruturais.
3. **Run/Step Mode:** Circuito com detector de borda/debounce para o botão manual no modo debug (`SW0` e `BUTTON1`).
4. **Conversor Hexadecimal-7 Segmentos Estrutural:** Implementar as funções lógicas estruturais para os segmentos de display e instanciar para os 4 displays (HEX3-HEX2 para PC, HEX1-HEX0 para AC).

### Frente 3: Integração e Entrega
1. **Top-Level Neander:** Conectar todos os blocos no Quartus.
2. **Atribuição de Pinos (.qsf):** Configurar botões, switches, LEDs e os 4 displays de 7 segmentos na placa DE0.
3. **Simulação e Captura:** Rodar o programa na memória e capturar os prints das ondas para a entrega no Moodle (`cartao1_cartao2.zip`).
