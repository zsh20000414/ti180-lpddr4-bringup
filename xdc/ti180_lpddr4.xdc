# TI180 LPDDR4 constraints — skeleton.
# Every exception below must carry a reason and the IP version it applies to.
# Anonymous false paths are not accepted in review.

create_clock -name clk_sys   -period 10.000 [get_ports clk_sys]
create_clock -name clk_ddr   -period  2.500 [get_ports clk_ddr_ref]

# --- LPDDR4 PHY interface -------------------------------------------------
# TODO: IO timing groups once the board pinout is final.

# --- Exceptions -----------------------------------------------------------
# Example of the required form:
# set_false_path -from [get_clocks clk_ddr] -to [get_pins .../sync_reg*/D] \
#   -comment "resets synchroniser; static after boot; controller IP 2026.1"

# No other exceptions are permitted until the path has been walked and written up.
