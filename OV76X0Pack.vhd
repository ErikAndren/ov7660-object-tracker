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
  constant GAUSSIAN_MODE          : natural := 3;
  constant MODES                  : natural := GAUSSIAN_MODE + 1;
  constant MODESW                 : natural := bits(MODES);

  type Cord is
  record
    X : word(FrameWW-1 downto 0);
    Y : word(FrameHW-1 downto 0);
  end record;
  
  constant Z_Cord : Cord :=
    (X => (others => '0'),
     Y => (others => '0'));

  constant MiddleXOfScreen : natural := FrameW/2;
  constant MiddleYOfScreen : natural := FrameH/2;

  constant MiddleOfScreen : Cord :=
    (X => conv_word(MiddleXOfScreen, FrameWW),
     Y => conv_word(MiddleYOfScreen, FrameHW));

  constant ServoResW       : positive := 8;
  constant ServoRes        : positive := 2**ServoResW;
  constant MiddleServoPos  : positive := ServoRes / 2;
  --
  constant ServoPitchMin   : natural  := 20;
  constant ServoPitchMax   : positive := 120;
  constant ServoPitchStart : positive := 80;
  constant ServoPitchRange : positive := ServoPitchMax - ServoPitchMin;
  --
--  constant ServoYawMin     : natural  := 30;
    constant ServoYawMin     : natural  := 40;
  constant ServoYawMax     : positive := 80;
--  constant ServoYawMax     : positive := 120;
  constant ServoYawStart   : positive := 50;
  constant ServoYawRange   : positive := ServoYawMax - ServoYawMin;
  --
  constant TileXRes        : positive := FrameW / ServoYawRange;
  constant TileXResW       : positive := bits(TileXRes);
  constant TileYRes        : positive := FrameH / ServoPitchRange;
  constant TileYResW       : positive := bits(TileYRes);

  constant ModeToggleAddr : natural := 16#00000010#;

  
  
end package;

package body OV76X0Pack is


end package body;
