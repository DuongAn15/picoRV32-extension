# ================================================================
#  Makefile — He thong kiem thu DSP cho PicoRV32
#  Cach dung:
#    make          → chay toan bo kiem thu
#    make wave     → mo GTKWave xem waveform
#    make clean    → xoa file build
#    make help     → xem huong dan
# ================================================================

# Duong dan toi picorv32.v (chinh lai neu can)
PICO_SRC = ../src/picorv32.v

# Cong cu
IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

# File dau ra
SIM_BIN  = sim_dsp
VCD_FILE = tb_dsp_pro.vcd
VCD_SAVE = tb_dsp_pro.gtkw

# Co bien dich
IVFLAGS  = -g2005

.PHONY: all sim wave clean help

# ── Chay toan bo ────────────────────────────────────────────────
all: sim

sim: $(SIM_BIN)
	@echo ""
	@echo "▶ Chay mo phong..."
	@$(VVP) $(SIM_BIN); EXIT=$$?; \
	if [ $$EXIT -eq 0 ]; then \
		echo "✅  TAT CA PASS"; \
	else \
		echo "❌  CO LOI — xem log va chay 'make wave' de debug"; \
	fi

$(SIM_BIN): tb_top.v $(PICO_SRC) \
            tb_golden.vh tb_rom.vh tb_tasks.vh \
            tc_normal.vh tc_boundary.vh \
            tc_overflow_negative.vh tc_random.vh
	@echo "▶ Bien dich..."
	$(IVERILOG) $(IVFLAGS) -o $@ tb_top.v $(PICO_SRC)

# ── Mo GTKWave ──────────────────────────────────────────────────
wave: $(VCD_FILE)
	@if [ -f $(VCD_SAVE) ]; then \
		$(GTKWAVE) $(VCD_FILE) $(VCD_SAVE) & \
	else \
		$(GTKWAVE) $(VCD_FILE) & \
	fi

$(VCD_FILE): sim

# ── Xoa file build ──────────────────────────────────────────────
clean:
	rm -f $(SIM_BIN) $(VCD_FILE)

# ── Huong dan ───────────────────────────────────────────────────
help:
	@echo ""
	@echo "  Cac lenh co the dung:"
	@echo ""
	@echo "  make              Bien dich va chay toan bo kiem thu"
	@echo "  make wave         Mo GTKWave xem waveform (sau khi chay)"
	@echo "  make clean        Xoa file build trung gian"
	@echo ""
	@echo "  Neu picorv32.v o noi khac:"
	@echo "  make PICO_SRC=/duong/dan/khac/picorv32.v"
	@echo ""
