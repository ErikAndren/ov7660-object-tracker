onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Literal /tb/ov7660signalgen/clkcnt
add wave -noupdate -format Literal /tb/ov7660signalgen/linecnt
add wave -noupdate -format Literal /tb/ov7660signalgen/pixcnt
add wave -noupdate -format Logic /tb/dut/vsync
add wave -noupdate -format Logic /tb/dut/href
add wave -noupdate -format Literal /tb/dut/d
add wave -noupdate -divider {VGA Generator}
add wave -noupdate -format Logic /tb/dut/vgagen/inview
add wave -noupdate -format Literal /tb/dut/vgagen/red
add wave -noupdate -format Literal /tb/dut/vgagen/green
add wave -noupdate -format Literal /tb/dut/vgagen/blue
add wave -noupdate -format Logic /tb/dut/vgagen/hsync
add wave -noupdate -format Logic /tb/dut/vgagen/vsync
add wave -noupdate -format Logic /tb/dut/vgagen/pixelclk
add wave -noupdate -divider Sccb
add wave -noupdate -format Logic /tb/dut/sccbm/ov7660i/nextinst
add wave -noupdate -format Literal /tb/dut/sccbm/ov7660i/instptr_d
add wave -noupdate -format Literal /tb/dut/sccbm/ov7660i/delay_d
add wave -noupdate -format Logic /tb/dut/sccbm/ov7660i/we
add wave -noupdate -format Logic /tb/dut/sccbm/ov7660i/start
add wave -noupdate -format Literal /tb/dut/sccbm/ov7660i/addrdata
add wave -noupdate -format Literal /tb/dut/sccbm/ov7660i/instptr
add wave -noupdate -format Logic /tb/dut/sccbm/ov7660i/clk
add wave -noupdate -format Logic /tb/dut/sccbm/ov7660i/rst_n
add wave -noupdate -format Logic /tb/dut/sccbm/sccbm/done
add wave -noupdate -format Literal /tb/dut/sccbm/sccbm/stm
add wave -noupdate -format Logic /tb/dut/sccbm/sccbm/data_pulse_i
add wave -noupdate -format Literal /tb/dut/fakevgacam/clkcnt
add wave -noupdate -format Literal /tb/dut/fakevgacam/linecnt
add wave -noupdate -format Literal /tb/dut/fakevgacam/pixcnt
add wave -noupdate -format Logic /tb/dut/fakevgacam/vsync
add wave -noupdate -format Logic /tb/dut/fakevgacam/href
add wave -noupdate -divider DitherFloydSteinberg
add wave -noupdate -format Logic /tb/dut/videocomp/pixelinval
add wave -noupdate -format Literal /tb/dut/videocomp/pixelin
add wave -noupdate -format Logic /tb/dut/videocomp/pixeloutval
add wave -noupdate -format Literal /tb/dut/videocomp/pixelout
add wave -noupdate -format Literal /tb/dut/videocomp/errorvect_d
add wave -noupdate -format Literal /tb/dut/captpixel/pixeldata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {969690000 ps} 0}
configure wave -namecolwidth 246
configure wave -valuecolwidth 201
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {575811583 ps} {1154291233 ps}
