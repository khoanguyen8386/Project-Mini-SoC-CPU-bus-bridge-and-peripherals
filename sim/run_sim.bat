@echo off
setlocal enabledelayedexpansion

pushd "%~dp0"

set RTL_DIR=..\rtl
set RTL_SRCS=%RTL_DIR%\ahb_lite_interconnect.v %RTL_DIR%\ahb_to_apb_bridge.v %RTL_DIR%\apb_clk_ctrl.v %RTL_DIR%\apb_gpio.v %RTL_DIR%\apb_timer.v %RTL_DIR%\apb_uart.v %RTL_DIR%\cpu_ahb_wrapper.v %RTL_DIR%\cpu_core_mips.v %RTL_DIR%\onchip_sram.v %RTL_DIR%\mini_soc_top.v
set CHECKER=ahb_protocol_checker.sv

echo.
echo [1/2] Compiling and running tb_unit_suite.sv...
iverilog -g2012 -o tb_unit_suite.vvp -s tb_unit_suite %RTL_SRCS% %CHECKER% tb_unit_suite.sv
if errorlevel 1 (
    echo [ERROR] Compilation of tb_unit_suite.sv failed!
    goto :fail
)
vvp tb_unit_suite.vvp
if errorlevel 1 (
    echo [ERROR] tb_unit_suite simulation failed!
    goto :fail
)

echo.
echo [2/2] Compiling and running tb_mini_soc.sv...
iverilog -g2012 -o tb_mini_soc.vvp -s tb_mini_soc %RTL_SRCS% %CHECKER% tb_mini_soc.sv
if errorlevel 1 (
    echo [ERROR] Compilation of tb_mini_soc.sv failed!
    goto :fail
)
vvp tb_mini_soc.vvp
if errorlevel 1 (
    echo [ERROR] tb_mini_soc simulation failed!
    goto :fail
)

echo.
echo [DONE] All simulations completed successfully!
popd
echo %cmdcmdline% | find /i "/c" >nul && pause
exit /b 0

:fail
popd
echo %cmdcmdline% | find /i "/c" >nul && pause
exit /b 1
