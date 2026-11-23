# Guia de Implementação: ID 7 - Registradores AC, RDM, REM e RI (Neander)

Este documento descreve detalhadamente o funcionamento, a implementação estrutural em Verilog e os testes dos registradores de 8 bits do processador Neander: **AC (Acumulador)**, **RDM (Registrador de Dados da Memória)**, **REM (Registrador de Endereço de Memória)** e **RI (Registrador de Instrução)**.

---

## 1. Requisitos e Papel na Arquitetura Neander

Conforme a especificação do Neander e a documentação em [`docs/OPCODES.md`](OPCODES.md):

| Registrador | Nome Completo | Função Principal no Processador Neander | Sinal de Habilitação | Origem dos Dados (`D`) | Destino Principal (`Q`) |
| :---: | :--- | :--- | :---: | :--- | :--- |
| **AC** | Acumulador | Armazena o operando principal e o resultado da ULA. | `cargaAC` | Saída $S[7:0]$ da ULA | Entrada $X[7:0]$ da ULA, RDM (em `STA`), Displays `HEX1` e `HEX0` |
| **RDM** | Registrador de Dados da Memória | Interface bidirecional de dados com a Memória ROM/RAM. | `cargaRDM` | Barramento de dados da memória ou saída do AC (em `STA` no passo $t_6$) | Entrada $Y[7:0]$ da ULA, MUX do REM, PC (desvios), RI, escrita de memória |
| **REM** | Registrador de Endereço da Memória | Fornece à memória o endereço da posição a ser lida ou escrita. | `cargaREM` | Saída do MUX do REM (selecionando `PC` ou `RDM`) | Barramento de endereços de 8 bits da memória (`addr[7:0]`) |
| **RI** | Registrador de Instrução | Armazena o byte da instrução corrente, capturado na busca ($t_2$). | `cargaRI` | Barramento de dados lido da memória | Decodificador de instruções (`RI[7:4]` $\rightarrow$ `decod_inst.v`) |

---

## 2. Arquitetura Estrutural (`reg1b` e `reg8`)

Todos os registradores utilizam a mesma célula básica estrutural de 1 bit (`reg1b`), replicada 8 vezes no módulo genérico `reg8`:

### 2.1. Lógica da Fatia de 1 Bit (`reg1b`)
Cada bit $i$ ($i = 0 \dots 7$) é implementado com:
1. **Multiplexador 2:1 estrutural (Portas NOT, AND, OR):**
   $$\text{next\_d}_i = (\text{load} \land d_i) \lor (\overline{\text{load}} \land q_i)$$
   * Quando $\text{load} = 1$: carrega o novo dado de entrada $d_i$ na borda de subida do clock.
   * Quando $\text{load} = 0$: realimenta a saída atual $q_i$, retendo o dado (modo *Hold*).
2. **Flip-Flop D estrutural (`ffd.v`):**
   * Armazenamento sincronizado na borda de subida (`posedge clk`).
   * Reset assíncrono ativo em 0 (`rst_n`), garantindo inicialização imediata e segura.

```
                  +-----+
    load -------->| NOT |------------------+
     |            +-----+                  |
     |                                     v
     |          +-----+                 +-----+
     +--------->| AND |---(w_d)-------->|     |
     |   d ---->|     |                 | OR  |---(next_d)---> [ D   Q ]---> q
     |          +-----+                 |     |                |  ffd  |
     |                                  |     |      clk ----> [ >     ]
     |          +-----+                 +-----+    rst_n ----> [ R_N   ]
     +--------->| AND |---(w_q)------------^
         q ---->|     |
                +-----+
```

---

## 3. Arquivos e Módulos Criados

| Arquivo | Módulo | Descrição |
| :--- | :--- | :--- |
| [`src/reg8.v`](../src/reg8.v) | `reg1b`, `reg8` | Fatia de 1 bit e módulo genérico de 8 bits com carga síncrona habilitada e reset assíncrono. |
| [`src/reg_ac.v`](../src/reg_ac.v) | `reg_ac` | Wrapper nominal para o Acumulador (porta `cargaAC`). |
| [`src/reg_rdm.v`](../src/reg_rdm.v) | `reg_rdm` | Wrapper nominal para o RDM (porta `cargaRDM`). |
| [`src/reg_rem.v`](../src/reg_rem.v) | `reg_rem` | Wrapper nominal para o REM (porta `cargaREM`). |
| [`src/reg_ri.v`](../src/reg_ri.v) | `reg_ri` | Wrapper nominal para o RI (porta `cargaRI`). |
| [`tb/tb_registradores.v`](../tb/tb_registradores.v) | `tb_registradores` | Testbench exaustivo com **48 verificações**. |

---

## 4. Testes e Validação

O testbench [`tb/tb_registradores.v`](../tb/tb_registradores.v) cobre todos os casos de teste essenciais:

1. **Reset Inicial Assíncrono:** Verifica se todos os 5 registradores inicializam em `8'h00` com `rst_n = 0`.
2. **Retenção de Dados (*Hold*):** Altera a entrada com `load = 0` e múltiplos pulsos de clock, verificando que o valor armazenado permanece inalterado.
3. **Carga Síncrona:** Testa cargas de valores variados (`0xA5`, `0x5A`) com `load = 1`.
4. **Reset Assíncrono Dinâmico:** Com clock parado, força `rst_n = 0` e verifica limpeza imediata para `8'h00`.
5. **Walking 1s (8 testes):** Testa individualmente cada bit em nível alto (`0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80`).
6. **Walking 0s (8 testes):** Testa individualmente cada bit em nível baixo (`0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F`).
7. **Isolamento de Carga entre AC, RDM, REM e RI:** Verifica se acionar `cargaAC`, `cargaRDM`, `cargaREM` ou `cargaRI` altera exclusivamente o registrador desejado sem afetar os demais.
8. **Reset Simultâneo:** Valida que o reset geral zera simultaneamente todos os registradores.

Para executar individualmente:
```bash
make tb_registradores
```
