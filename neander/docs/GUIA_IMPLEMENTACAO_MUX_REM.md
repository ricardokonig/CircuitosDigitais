# Guia de Implementação: ID 3 - MUX do REM (Neander)

Este documento descreve detalhadamente o funcionamento, a implementação em Verilog e os testes do **Multiplexador do Registrador de Endereço de Memória (MUX do REM)** do processador Neander, conforme os arquivos [`src/mux2x1_8b.v`](../src/mux2x1_8b.v) e [`src/mux_rem.v`](../src/mux_rem.v).

---

## 1. Requisitos e Papel na Arquitetura Neander

Conforme a especificação do Neander e a documentação em [`docs/OPCODES.md`](OPCODES.md):

* **Função:** Selecionar qual registrador fornece o endereço de 8 bits a ser carregado no **REM** (*Registrador de Endereço de Memória*):
  * **Program Counter (`PC`)**: durante as fases de busca de instrução ($t_0$) e busca do endereço do operando ($t_3$).
  * **Registrador de Dados da Memória (`RDM`)**: durante a fase de acesso ao operando/dado na memória ($t_5$) para instruções com endereçamento direto (`STA`, `LDA`, `ADD`, `OR`, `AND`).
* **Restrição da Tabela I:** Livre (`-`), ou seja, **não exige implementação estrutural restrita a portas primitivas**, permitindo modelagem combinacional limpa e otimizada (`assign out = sel ? d1 : d0;`).
* **Sinal de Controle `sel`:**
  * Gerado pela Unidade de Controle (`unidade_controle.v` / `controle_top.v`):
    $$\text{sel} = t_5 \land (\text{sta} \lor \text{lda} \lor \text{add} \lor \text{or\_op} \lor \text{and\_op})$$
  * `sel = 0`: Seleciona `PC` (entrada 0).
  * `sel = 1`: Seleciona `RDM` (entrada 1).

---

## 2. Diagrama de Conexão no Datapath

```
        +--------------+                 +---------------+
        |   PC [7:0]   |                 |   RDM [7:0]   |
        +-------+------+                 +-------+-------+
                |                                |
                | (sel = 0)                      | (sel = 1)
                v                                v
          +-----------+                    +-----------+
          |    d0     |                    |    d1     |
          +-----------+--------------------+-----------+
          |                mux2x1_8b                   |
          |       (ou encapsulado em mux_rem)          |
          +---------------------+----------------------+
                                ^
                                | sel (da Unidade de Controle)
                                |
                                v out / rem [7:0]
                        +-------+-------+
                        |   REM [7:0]   | (habilitado por cargaREM)
                        +---------------+
                                |
                                v
                        Memória (ROM/RAM)
```

---

## 3. Tabela Verdade

| Sinal `sel` | Entrada Selecionada | Saída `out` / `rem` | Ciclos do Neander Típicos | Finalidade |
| :---: | :---: | :---: | :---: | :--- |
| `0` | `d0` (`PC`) | `PC[7:0]` | $t_0$, $t_3$ | Busca do opcode da instrução ou do endereço do operando apontado pelo Program Counter. |
| `1` | `d1` (`RDM`) | `RDM[7:0]` | $t_5$ | Acesso à posição de memória do dado apontada pelo operando (instruções `STA`, `LDA`, `ADD`, `OR`, `AND`). |

---

## 4. Códigos Verilog

Foram disponibilizados dois módulos complementares em `src/`:

### 4.1. Módulo Básico Genérico: [`src/mux2x1_8b.v`](../src/mux2x1_8b.v)
Ideal para reutilização genérica como multiplexador 2:1 de 8 bits em qualquer ponto do datapath:

```verilog
`timescale 1ns/1ns

module mux2x1_8b (
    input  wire [7:0] d0,   // Entrada 0 (sel = 0 -> PC)
    input  wire [7:0] d1,   // Entrada 1 (sel = 1 -> RDM)
    input  wire       sel,  // Seletor: 0 seleciona d0, 1 seleciona d1
    output wire [7:0] out   // Saida de 8 bits para o REM
);

    assign out = sel ? d1 : d0;

endmodule
```

### 4.2. Módulo Semântico do Neander: [`src/mux_rem.v`](../src/mux_rem.v)
Encapsula o `mux2x1_8b` expondo diretamente os nomes dos sinais do Neander (`pc`, `rdm`, `sel`, `rem`), facilitando a conexão no esquemático top-level:

```verilog
`timescale 1ns/1ns

module mux_rem (
    input  wire [7:0] pc,   // Barramento vindo do Program Counter
    input  wire [7:0] rdm,  // Barramento vindo do Registrador de Dados
    input  wire       sel,  // Sinal de selecao (0 = PC, 1 = RDM)
    output wire [7:0] rem   // Endereco selecionado para a entrada do REM
);

    mux2x1_8b u_mux (
        .d0(pc),
        .d1(rdm),
        .sel(sel),
        .out(rem)
    );

endmodule
```

---

## 5. Simulação e Testbench

O testbench [`tb/tb_mux_rem.v`](../tb/tb_mux_rem.v) realiza **32 verificações automatizadas**, incluindo:
1. **Testes Unitários com `sel = 0`:** Confirma que qualquer valor em `d0` é transferido para a saída e que ruídos/variações em `d1` são completamente ignorados.
2. **Testes Unitários com `sel = 1`:** Confirma que qualquer valor em `d1` é transferido para a saída e que variações em `d0` são completamente ignoradas.
3. **Validação do Módulo Semântico `mux_rem`:** Testa a alternância rápida de seleção entre `pc` e `rdm`.
4. **Ciclos Reais do Neander:** Simula a transição sequencial $t_0 \rightarrow t_3 \rightarrow t_5 \rightarrow t_0$.
5. **Walking Ones / Zeros:** Varredura bit a bit cobrindo todas as 8 linhas de dados para descartar curtos ou bits presos (*stuck-at*).

### Como Executar os Testes

Para executar apenas o testbench do MUX:
```bash
make tb_mux_rem
```

Para rodar todos os testes do projeto Neander:
```bash
make test
```

Para inspecionar as formas de onda geradas no GTKWave:
```bash
make wave VCD=tb/tb_mux_rem.vcd
```
