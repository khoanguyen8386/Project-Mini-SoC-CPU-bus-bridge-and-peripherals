# Mini-SoC Simulation Makefile (Icarus Verilog + GTKWave)
IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave
FLAGS    ?= -g2012 -Wall

RTL_DIR  := ../rtl
RTL_SRCS := \
	$(RTL_DIR)/ahb_lite_interconnect.v \
	$(RTL_DIR)/ahb_to_apb_bridge.v \
	$(RTL_DIR)/apb_clk_ctrl.v \
	$(RTL_DIR)/apb_gpio.v \
	$(RTL_DIR)/apb_timer.v \
	$(RTL_DIR)/apb_uart.v \
	$(RTL_DIR)/cpu_ahb_wrapper.v \
	$(RTL_DIR)/cpu_core_mips.v \
	$(RTL_DIR)/onchip_sram.v \
	$(RTL_DIR)/mini_soc_top.v

CHECKER  := ahb_protocol_checker.sv

.PHONY: all unit soc wave clean

all: unit soc

unit: tb_unit_suite.vvp
	$(VVP) tb_unit_suite.vvp

soc: tb_mini_soc.vvp
	$(VVP) tb_mini_soc.vvp

tb_unit_suite.vvp: $(RTL_SRCS) $(CHECKER) tb_unit_suite.sv
	$(IVERILOG) $(FLAGS) -o $@ -s tb_unit_suite $(RTL_SRCS) $(CHECKER) tb_unit_suite.sv

tb_mini_soc.vvp: $(RTL_SRCS) $(CHECKER) tb_mini_soc.sv
	$(IVERILOG) $(FLAGS) -o $@ -s tb_mini_soc $(RTL_SRCS) $(CHECKER) tb_mini_soc.sv

wave: soc
	$(GTKWAVE) tb_mini_soc.vcd gtkwave_setup.gtkw &

clean:
	rm -f *.vvp *.vcd
