transcript on
if {[file exists work]} {
	vdel -lib work -all
}
vlib work
vmap work work

vlog -vlog01compat -work work +incdir+/home/liam/repos/astrogate/db {/home/liam/repos/astrogate/db/hdmi_pll_altpll.v}
vcom -autoorder -2008 -work work {/home/liam/repos/astrogate/rtl/hdmi/hdmi_pll/hdmi_pll.vhd}
vcom -autoorder -2008 -work work {/home/liam/repos/astrogate/rtl/hdmi/**.vhd}

vcom -autoorder -2008 -work work {/home/liam/repos/astrogate/tb_astrogate_top.vhd}

vsim -t 1ps -l altera -l lpm -l sgate -l altera_mf -l altera_lnsim -l cycloneive -l rtl_work -l work -voptargs="+acc"  tb_astrogate_top

add wave *
view structure
view signals
run -all
