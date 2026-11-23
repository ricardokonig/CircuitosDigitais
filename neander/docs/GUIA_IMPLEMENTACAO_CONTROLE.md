# Guia de Implementação: Unidade de Controle e Temporização (IDs 1, 2, 10, 11)

Este documento detalha o funcionamento, as equações lógicas e a integração da **Unidade de Controle e Temporizador** do processador Neander.

---

## 1. Visão Geral do Módulo de Controle

A Unidade de Controle do Neander é do tipo **hardwired combinacional** (sem uso de máquina de estados FSM explícita com cláusulas `case`). O sequenciamento temporal é realizado por um **Temporizador em Anel** de 8 passos ($t_0 \dots t_7$).

```mermaid
flowchart LR
    CLK["clk"] --> TEMP["Temporizador (ID 10)<br/>src/temporizador.v"]
    RST["rst_n"] --> TEMP
    GOTO["goto_t0"] --> TEMP
    HLT["hlt"] --> TEMP

    TEMP -->|t0..t7| UC["Unidade de Controle (ID 11)<br/>src/unidade_controle.v"]
    OP["RI[7:4]"] --> DEC["Decodificador (ID 1)<br/>src/decod_inst.v"]
    DEC -->|11 linhas| UC
    FLAGS["flag_n, flag_z"] --> UC

    UC --> COD["Codificador ULA (ID 2)<br/>src/codificador_ula.v"]
    COD -->|selUAL[2:0]| SAIDA_ULA["Comandos da ULA"]
    UC -->|Sinais de Controle| SAIDA_DP["Sinais do Datapath"]
```

---

## 2. Componentes Internos

### 2.1. ID 10: Temporizador (`src/temporizador.v`)
* **Estrutura:** 8 Flip-Flops D (`ffd.v`) conectados em anel.
* **Passos:** No reset, $t_0 = 1$ e $t_1 \dots t_7 = 0$. A cada borda de subida do clock, o nível alto avança para o próximo estágio.
* **Sinais Especiais:**
  - `goto_t0`: Quando ativado pela UC, o passo atual encerra e $t_0$ é ativado no próximo flanco de subida.
  - `hlt`: Desabilita o avanço e congela o temporizador no passo em que o opcode HLT (`1111`) é decodificado.

### 2.2. ID 1: Decodificador de Instruções (`src/decod_inst.v`)
* **Estrutura:** Decodificador estrutural 4 para 16 com portas lógicas primitivas (`not`, `and`), mapeando os 4 bits mais significativos de `RI`:
  - `0000` (0x0): `nop`
  - `0001` (0x1): `sta`
  - `0010` (0x2): `lda`
  - `0011` (0x3): `add`
  - `0100` (0x4): `or_op`
  - `0101` (0x5): `and_op`
  - `0110` (0x6): `not_op`
  - `1000` (0x8): `jmp`
  - `1001` (0x9): `jn`
  - `1010` (0xA): `jz`
  - `1111` (0xF): `hlt`

### 2.3. ID 11: Unidade de Controle Combinacional (`src/unidade_controle.v`)
Implementa as 16 expressões booleanas clássicas do Neander:
1. $\text{cargaREM} = t_0 + t_3 \cdot (\text{sta} + \text{lda} + \text{add} + \text{or} + \text{and} + \text{jmp} + \text{jn} \cdot N + \text{jz} \cdot Z) + t_5 \cdot (\text{sta} + \text{lda} + \text{add} + \text{or} + \text{and})$
2. $\text{sel} = t_5 \cdot (\text{sta} + \text{lda} + \text{add} + \text{or} + \text{and})$
3. $\text{read} = t_1 + t_4 \cdot (\text{sta} + \text{lda} + \text{add} + \text{or} + \text{and} + \text{jmp} + \text{jn} \cdot N + \text{jz} \cdot Z) + t_6 \cdot (\text{lda} + \text{add} + \text{or} + \text{and})$
4. $\text{write} = t_7 \cdot \text{sta}$
5. $\text{incrementaPC} = t_1 + t_4 \cdot (\text{sta} + \text{lda} + \text{add} + \text{or} + \text{and} + \text{jmp} + \text{jn} \cdot N + \text{jz} \cdot Z) + t_3 \cdot (\text{jn} \cdot \overline{N} + \text{jz} \cdot \overline{Z})$
6. $\text{cargaPC} = t_5 \cdot (\text{jmp} + \text{jn} \cdot N + \text{jz} \cdot Z)$
7. $\text{cargaRI} = t_2$
8. $\text{cargaRDM} = t_6 \cdot \text{sta}$
9. $\text{cargaAC} = t_3 \cdot \text{not} + t_7 \cdot (\text{sta} + \text{lda} + \text{add} + \text{or} + \text{and})$
10. $\text{cargaNZ} = \text{cargaAC}$
11. $\text{ula\_y} = t_7 \cdot \text{lda}$
12. $\text{ula\_add} = t_7 \cdot \text{add}$
13. $\text{ula\_and} = t_7 \cdot \text{and}$
14. $\text{ula\_or} = t_7 \cdot \text{or}$
15. $\text{ula\_not} = t_3 \cdot \text{not}$
16. $\text{goto\_t0} = t_3 \cdot (\text{nop} + \text{not} + \text{jn} \cdot \overline{N} + \text{jz} \cdot \overline{Z}) + t_5 \cdot (\text{jmp} + \text{jn} \cdot N + \text{jz} \cdot Z) + t_7 \cdot (\text{sta} + \text{lda} + \text{add} + \text{or} + \text{and})$

### 2.4. ID 2: Codificador da ULA (`src/codificador_ula.v`)
* Converte os 5 comandos individuais da ULA no barramento de 3 bits `selUAL`:
  - `selUAL[0] = ula_add | ula_or`
  - `selUAL[1] = ula_and | ula_or`
  - `selUAL[2] = ula_not`

---

## 3. Testes e Validação (`tb/tb_controle.v`)

O testbench [tb_controle.v](file:///home/schons/Documentos/facul/CD/CircuitosDigitais/neander/tb/tb_controle.v) valida:
1. Avanço cíclico e comandos especiais do temporizador ($t_0 \dots t_7$, `goto_t0`, `hlt`).
2. Todos os 16 opcodes de 4 bits (`0000` a `1111`).
3. Todas as 16 saídas de controle em cada passo de tempo para as 11 instruções.
Total de 130 verificações aprovadas com 0 falhas.
