# Guia de Testes e Simulação: Processador Neander

Este documento instrui como executar simulações, analisar formas de onda e adicionar novos testbenches ao projeto Neander utilizando o [Makefile](file:///home/schons/Documentos/faculdade/3/ProjetoCD/trab/neander/Makefile) e ferramentas como **Icarus Verilog (`iverilog`)**, **VVP** e **GTKWave**.

---

## 1. Estrutura do Ambiente de Testes

Os arquivos do projeto estão organizados da seguinte forma:

```text
neander/
├── Makefile               # Automação de compilação, simulação e limpeza
├── src/                   # Módulos Verilog sintetizáveis (RTL estrutural)
│   ├── ffd.v
│   ├── decod_inst.v
│   ├── codificador_ula.v
│   ├── temporizador.v
│   ├── unidade_controle.v
│   └── controle_top.v
├── tb/                    # Testbenches e formas de onda geradas
│   ├── tb_controle.v
│   └── tb_controle.vcd
└── docs/                  # Guias e documentação técnica
```

---

## 2. Execução Automatizada com o Makefile

Todos os comandos abaixo devem ser executados a partir da raiz da pasta `neander/`:

```bash
cd /home/schons/Documentos/faculdade/3/ProjetoCD/trab/neander
```

### 2.1. Rodar Todos os Testbenches
Para compilar e executar todos os testbenches existentes na pasta `tb/`:
```bash
make test
# ou simplesmente:
make
```
O Makefile varre dinamicamente a pasta `tb/`, compila cada arquivo `tb_*.v` junto com os fontes de `src/`, executa a simulação e move os arquivos `.vcd` gerados para `tb/`.

### 2.2. Rodar um Testbench Específico
Se você estiver trabalhando em um módulo específico e quiser rodar apenas o teste dele (sem esperar os outros):
```bash
make tb_<nome>
```
**Exemplos:**
```bash
make tb_controle   # Roda apenas tb/tb_controle.v
make tb_pc         # Roda apenas tb/tb_pc.v (quando criado)
make tb_ula        # Roda apenas tb/tb_ula.v (quando criado)
```

### 2.3. Visualizar Formas de Onda no GTKWave
Para abrir as formas de onda no visualizador:
```bash
# Abre o VCD padrão (tb_controle.vcd):
make wave

# Abre o VCD de um teste específico:
make wave VCD=tb/tb_pc.vcd
```

### 2.4. Limpar Arquivos Temporários
Para apagar os binários compilados (`bin/`) e arquivos de onda (`.vcd`):
```bash
make clean
```

---

## 3. Como Adicionar Novos Testbenches

O Makefile foi programado para **autodescoberta** através do padrão `tb/tb_*.v`. Para criar e integrar um novo teste:

### Passo 1: Criar o arquivo em `tb/` com o prefixo `tb_`
Crie o novo arquivo na pasta `tb/`, por exemplo:
- `tb/tb_pc.v` (para testar o Program Counter)
- `tb/tb_ula.v` (para testar a ULA)
- `tb/tb_divisor.v` (para testar o divisor de clock)

### Passo 2: Configurar o Dump de Ondas no Testbench (Opcional, mas recomendado)
Dentro do bloco `initial` do seu novo testbench, adicione as diretivas para gravação do arquivo `.vcd`:
```verilog
initial begin
    $dumpfile("tb_pc.vcd");
    $dumpvars(0, tb_pc); // Substitua 'tb_pc' pelo nome do modulo de testbench
end
```

### Passo 3: Executar
Não é necessário editar o [Makefile](file:///home/schons/Documentos/faculdade/3/ProjetoCD/trab/neander/Makefile). O novo teste já estará integrado:
- Para rodar junto com os demais: `make test`
- Para rodar individualmente: `make tb_pc`

---

## 4. Execução Manual via Terminal (sem Makefile)

Se preferir utilizar diretamente os utilitários da linha de comando:

### Opção A: Incluindo os arquivos de `src/*.v`
```bash
cd neander
mkdir -p bin
iverilog -o bin/sim_pc tb/tb_pc.v src/*.v
vvp bin/sim_pc
```

### Opção B: Usando a flag de biblioteca `-y`
A flag `-y src` faz o compilador buscar automaticamente dentro da pasta `src/` os módulos que forem instanciados:
```bash
cd neander
mkdir -p bin
iverilog -y src -o bin/sim_pc tb/tb_pc.v
vvp bin/sim_pc
```

---

## 5. Execução no ModelSim / QuestaSim (Quartus)

Para simular pela ferramenta gráfica ou pelo console Tcl do ModelSim:

```tcl
# Compila todos os fontes e o testbench desejado:
vlog src/*.v tb/tb_controle.v

# Inicia a simulação do módulo top do testbench:
vsim tb_controle

# Adiciona todos os sinais à janela Wave:
add wave *

# Executa até o $finish:
run -all
```
