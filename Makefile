# Music Player - Verilog + 555 Timer Simulation
# Supports: Yosys (synthesis), Verilator (simulation), Emscripten (web)

# Paths
SRC_DIR = src
RTL_DIR = $(SRC_DIR)/rtl
SIM_DIR = $(SRC_DIR)/verilator
WEB_SRC = $(SRC_DIR)/web
WEB_OUT = $(OUT_DIR)/web
OUT_DIR = output

# Source files
SRC = $(RTL_DIR)/music_player.v
TB  = $(SIM_DIR)/top.cpp
TOP = music_player

.PHONY: all synth verilator run web serve schematics gates clean help

#------------------------------------------------------------------------------
# Verilator Simulation (native)
#------------------------------------------------------------------------------
VERILATOR_DIR = $(OUT_DIR)/obj_dir

verilator:
	@mkdir -p $(VERILATOR_DIR)
	verilator --cc --exe -CFLAGS "-O3" -Wno-fatal \
		--Mdir $(VERILATOR_DIR) -I$(SIM_DIR) $(SRC) $(TB) -o music_player_verilator
	$(MAKE) -C $(VERILATOR_DIR) -f Vmusic_player.mk

run: verilator
	./$(VERILATOR_DIR)/music_player_verilator
	@mv -f music_555.wav $(OUT_DIR)/ 2>/dev/null || true
	@echo "Output: $(OUT_DIR)/music_555.wav"

#------------------------------------------------------------------------------
# Emscripten (web)
#------------------------------------------------------------------------------
VERILATOR_INC = $(shell verilator --getenv VERILATOR_ROOT)/include

web:
	@mkdir -p $(WEB_OUT)/obj_dir
	verilator --cc -Wno-fatal --no-threads --Mdir $(WEB_OUT)/obj_dir $(SRC)
	em++ -O3 -I$(SIM_DIR) -I$(WEB_OUT)/obj_dir -I$(VERILATOR_INC) \
		-include $(SIM_DIR)/verilator_wasm.h \
		$(TB) $(SIM_DIR)/verilator_stubs.cpp $(WEB_OUT)/obj_dir/*.cpp \
		$(VERILATOR_INC)/verilated.cpp \
		-s WASM=1 -s EXPORTED_RUNTIME_METHODS='["FS"]' \
		-s EXPORTED_FUNCTIONS='["_main","_web_run"]' \
		-s INVOKE_RUN=0 \
		-s ASYNCIFY -s ASYNCIFY_IMPORTS='["emscripten_sleep"]' \
		-o $(WEB_OUT)/music_player.js
	@cp $(WEB_SRC)/index.html $(WEB_OUT)/
	@echo "Output: $(WEB_OUT)/"

serve: web
	@echo "Starting server at http://localhost:8000"
	cd $(WEB_OUT) && python3 -m http.server 8000

#------------------------------------------------------------------------------
# Yosys Synthesis
#------------------------------------------------------------------------------
synth:
	yosys -p "read_verilog $(SRC); synth -top $(TOP); stat"

#------------------------------------------------------------------------------
# Schematics
#------------------------------------------------------------------------------
SCHEMATIC_DIR = $(OUT_DIR)/schematics
GATES_DIR = $(SCHEMATIC_DIR)/gates

schematics:
	@mkdir -p $(SCHEMATIC_DIR)
	@echo "Generating RTL schematics..."
	@yosys -q -p "read_verilog $(SRC); prep -top music_player; flatten; show -format dot -prefix $(SCHEMATIC_DIR)/music_player"
	@dot -Tpng $(SCHEMATIC_DIR)/music_player.dot -o $(SCHEMATIC_DIR)/music_player.png
	@yosys -q -p "read_verilog $(SRC); prep -top music_rom; show -format dot -prefix $(SCHEMATIC_DIR)/music_rom"
	@dot -Tpng $(SCHEMATIC_DIR)/music_rom.dot -o $(SCHEMATIC_DIR)/music_rom.png
	@echo "Done: $(SCHEMATIC_DIR)/*.png"

gates:
	@mkdir -p $(GATES_DIR)
	@echo "Generating gate-level schematics..."
	@yosys -q -p "read_verilog $(SRC); synth -top music_player; flatten; show -format dot -prefix $(GATES_DIR)/music_player"
	@dot -Tpng $(GATES_DIR)/music_player.dot -o $(GATES_DIR)/music_player.png
	@yosys -q -p "read_verilog $(SRC); synth -top music_rom; show -format dot -prefix $(GATES_DIR)/music_rom"
	@dot -Tpng $(GATES_DIR)/music_rom.dot -o $(GATES_DIR)/music_rom.png
	@echo "Done: $(GATES_DIR)/*.png"

#------------------------------------------------------------------------------
# Utilities
#------------------------------------------------------------------------------
all: synth run

clean:
	rm -rf $(VERILATOR_DIR)
	rm -rf $(WEB_OUT)
	rm -f $(OUT_DIR)/*.wav
	rm -rf $(SCHEMATIC_DIR)

help:
	@echo "Music Player Makefile"
	@echo ""
	@echo "  make run        - Build & run native simulation (WAV)"
	@echo "  make web        - Build for web (Emscripten)"
	@echo "  make serve      - Build & start local web server"
	@echo "  make synth      - Yosys synthesis"
	@echo "  make schematics - Generate RTL schematics (PNG)"
	@echo "  make gates      - Generate gate-level schematics"
	@echo "  make clean      - Remove generated files"
