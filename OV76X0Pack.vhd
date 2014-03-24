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

  constant NoPixels  : positive := SramDataW / PixelResW;
  constant NoPixelsW : positive := bits(NoPixels);

  constant NoBuffers  : positive := 2;
  constant NoBuffersW : positive := bits(NoBuffers);

  constant BufferAddrOffs : positive := 16#10000#;

  constant FrameW   : positive := 640;
  constant FrameWW  : positive := bits(FrameW);
  constant FrameH   : positive := 480;
  constant FrameHW  : positive := bits(FrameH);
  constant FrameRes : positive := FrameW * FrameH;

  constant MemWordsPerLine  : positive := FrameW / NoPixels;
  constant MemWordsPerLineW : positive := bits(MemWordsPerLine);

  constant InstPtrW : positive := 4;

  constant tClk  : positive := 1;
  constant tP    : positive := 2 * tClk;
  constant tLine : positive := tP * 784;

  constant tVsyncPeriod : positive := tLine * 510;
  constant tVsyncHigh   : positive := 4;

  constant tHrefPreamble  : positive := tVsyncHigh + 11;
  constant tHrefPostamble : positive := 15;
  constant noHrefs        : positive := 480;

  constant tHrefHigh   : positive := 640 * tP;
  constant tHrefLow    : positive := 144 * tP;
  constant tHrefPeriod : positive := tHrefHigh + tHrefLow;

  constant PixelW : positive := 8;
  type PixVec is array (3-1 downto 0) of word(PixelW-1 downto 0);
  type PixVec2D is array (natural range <>) of PixVec;


  constant NONE_MODE              : natural := 0;
  constant DITHER_MODE            : natural := 1;
  constant SOBEL_MODE             : natural := 2;
  constant LAPLACIAN_1_MODE       : natural := 3;
  constant LAPLACIAN_2_MODE       : natural := 4;
  constant MODES                  : natural := LAPLACIAN_2_MODE + 1;
  constant MODESW                 : natural := bits(MODES);

end package;

package body OV76X0Pack is


end package body;
