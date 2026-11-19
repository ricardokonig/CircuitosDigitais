# Makefile para Simulação do Projeto Neander
CC     = iverilog
SIM    = vvp
VIEWER = gtkwave

SRC_DIR = src
TB_DIR  = tb
BIN_DIR = bin

SRCS    = $(wildcard $(SRC_DIR)/*.v)
TBS     = $(wildcard $(TB_DIR)/tb_*.v)

.PHONY: all test wave clean

all: test

# 1. Compila e executa TODOS os testbenches em tb/ (tb_*.v) automaticamente
test:
	@mkdir -p $(BIN_DIR)
	@for tb in $(TBS); do \
		name=$$(basename $$tb .v); \
		echo ""; \
		echo "=================================================="; \
		echo "  Compilando e Executando: $$tb"; \
		echo "=================================================="; \
		$(CC) -y $(SRC_DIR) -o $(BIN_DIR)/$$name $$tb $(SRCS) || exit 1; \
		$(SIM) $(BIN_DIR)/$$name || exit 1; \
	done
	@mv -f *.vcd $(TB_DIR)/ 2>/dev/null || true

# 2. Rodar um testbench individual pelo nome do módulo (ex: make tb_controle, make tb_pc)
tb_%: $(TB_DIR)/tb_%.v
	@mkdir -p $(BIN_DIR)
	@echo "Executando $<..."
	$(CC) -y $(SRC_DIR) -o $(BIN_DIR)/$@ $< $(SRCS)
	$(SIM) $(BIN_DIR)/$@
	@mv -f *.vcd $(TB_DIR)/ 2>/dev/null || true

# 3. Abrir GTKWave (padrão tb_controle.vcd ou: make wave VCD=tb/outro.vcd)
VCD ?= $(TB_DIR)/tb_controle.vcd
wave:
	$(VIEWER) $(VCD) &

# 4. Limpar executáveis e arquivos de onda
clean:
	rm -rf $(BIN_DIR) $(TB_DIR)/*.vcd *.vcd

