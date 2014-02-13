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
add wave -noupdate -format Logic /tb/dut/vgagen/red
add wave -noupdate -format Logic /tb/dut/vgagen/green
add wave -noupdate -format Logic /tb/dut/vgagen/blue
add wave -noupdate -format Logic /tb/dut/vgagen/hsync
add wave -noupdate -format Logic /tb/dut/vgagen/vsync
add wave -noupdate -format Logic /tb/dut/vgagen/pixelclk
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1094846209 ps} 0}
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
WaveRestoreZoom {1094705936 ps} {1095034064 ps}
