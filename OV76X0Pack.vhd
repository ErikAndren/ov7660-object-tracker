library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

package OV76X0Pack is
	constant SccbAddrW : positive := 8;
	constant SccbDataW : positive := 8;

	constant SramDataW : positive := 16;
	constant SramAddrW : positive := 18;

	constant PixelResW : positive := 3;
	
	constant NoPixels : positive := SramDataW / PixelResW;
	constant NoPixelsW : positive := bits(NoPixels);
	
	constant NoBuffers : positive := 2;
	constant NoBuffersW : positive := bits(NoBuffers);
	
	constant BufferAddrOffs : positive := 16#10000#;
	
	constant FrameW : positive := 640;
	constant FrameH : positive := 480;
	constant FrameHW : positive := bits(FrameH);
	constant FrameRes : positive := FrameW * FrameH;
	
	constant MemWordsPerLine : positive := FrameW / NoPixels;
	constant MemWordsPerLineW : positive := bits(MemWordsPerLine);

end package;

package body OV76X0Pack is


end package body;