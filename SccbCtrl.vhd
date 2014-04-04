library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;

entity SccbCtrl is
  port (
    clk_i        : in    bit1;
    rst_i        : in    bit1;
    sccb_clk_i   : in    bit1;
    data_pulse_i : in    bit1;
    addr_i       : in    word(8-1 downto 0);
    data_i       : in    word(16-1 downto 0);
    data_o       : out   word(8-1 downto 0);
    rw_i         : in    bit1;
    start_i      : in    bit1;
    ack_error_o  : out   bit1;
    done_o       : out   bit1;
    sioc_o       : out   bit1;
    siod_io      : inout bit1
    );
end entity;

architecture fpga of SccbCtrl is
  signal sccb_stm_clk : bit1;
  signal stm          : word(7-1 downto 0);
  signal bit_out      : bit1;
  signal ack_err      : bit1;

  signal done : bit1;
  
begin
  done_o <= done;

  sioc_o <= sccb_clk_i when start_i = '1' and
((stm >= 5 and stm  <= 12) or stm = 14 or
 (stm >= 16 and stm <= 23) or stm = 25 or
 (stm >= 27 and stm <= 34) or stm = 36 or
 (stm >= 44 and stm <= 51) or stm = 53 or
 (stm >= 55 and stm <= 62) or stm = 64)
            else sccb_stm_clk;
  
  siod_io <= 'Z' when stm <= 62 and
             (stm = 13 or
              stm = 14 or
              stm = 24 or
              stm = 25 or
              stm = 35 or
              stm = 36 or
              stm = 52 or
              stm = 53 or
              stm >= 54)
             else bit_out;
  ack_error_o <= ack_err;

  SyncProc : process (Rst_i, Clk_i)
  begin
    if Rst_i = '0' then
      stm          <= (others => '0');
      sccb_stm_clk <= '1';
      bit_out      <= '1';
      data_o       <= (others => '0');
      done         <= '0';
      ack_err      <= '1';
      
    elsif rising_edge(Clk_i) then
      done <= '0';
      if Data_pulse_i = '1' then
        if (start_i = '0') then
          stm <= (others => '0');
        elsif (rw_i = '0' and stm = 25) then
          stm <= conv_word(37, stm'length);
        elsif (rw_i = '1' and stm = 36) then
          stm <= conv_word(65, stm'length);
        elsif (stm < 68) then
          stm <= stm + 1;
        end if;

        if start_i = '1' then
          case stm is
            when conv_word(0, stm'length) =>
              bit_out <= '1';
            when conv_word(1, stm'length) =>
              bit_out <= '1';

                                        --Start write transaction.
            when conv_word(2, stm'length) =>
              bit_out <= '0';
            when conv_word(3, stm'length) =>
              sccb_stm_clk <= '0';

                                        -- Write device`s ID address.
            when conv_word(4, stm'length) =>
              bit_out <= addr_i(7);
            when conv_word(5, stm'length) =>
              bit_out <= addr_i(6);
            when conv_word(6, stm'length) =>
              bit_out <= addr_i(5);
            when conv_word(7, stm'length) =>
              bit_out <= addr_i(4);
            when conv_word(8, stm'length) =>
              bit_out <= addr_i(3);
            when conv_word(9, stm'length) =>
              bit_out <= addr_i(2);
            when conv_word(10, stm'length) =>
              bit_out <= addr_i(1);
            when conv_word(11, stm'length) =>
              bit_out <= '0';
            when conv_word(12, stm'length) =>
              bit_out <= '0';
            when conv_word(13, stm'length) =>
              ack_err <= siod_io;
            when conv_word(14, stm'length) =>
              bit_out <= '0';

                                        -- Write register address.
            when conv_word(15, stm'length) =>
              bit_out <= data_i(15);
            when conv_word(16, stm'length) =>
              bit_out <= data_i(14);
            when conv_word(17, stm'length) =>
              bit_out <= data_i(13);
            when conv_word(18, stm'length) =>
              bit_out <= data_i(12);
            when conv_word(19, stm'length) =>
              bit_out <= data_i(11);
            when conv_word(20, stm'length) =>
              bit_out <= data_i(10);
            when conv_word(21, stm'length) =>
              bit_out <= data_i(9);
            when conv_word(22, stm'length) =>
              bit_out <= data_i(8);
            when conv_word(23, stm'length) =>
              bit_out <= '0';
            when conv_word(24, stm'length) =>
              ack_err <= siod_io;
            when conv_word(25, stm'length) =>
              bit_out <= '0';

                                        -- Write data. This concludes 3-phase write transaction.
            when conv_word(26, stm'length) =>
              bit_out <= data_i(7);
            when conv_word(27, stm'length) =>
              bit_out <= data_i(6);
            when conv_word(28, stm'length) =>
              bit_out <= data_i(5);
            when conv_word(29, stm'length) =>
              bit_out <= data_i(4);
            when conv_word(30, stm'length) =>
              bit_out <= data_i(3);
            when conv_word(31, stm'length) =>
              bit_out <= data_i(2);
            when conv_word(32, stm'length) =>
              bit_out <= data_i(1);
            when conv_word(33, stm'length) =>
              bit_out <= data_i(0);
            when conv_word(34, stm'length) =>
              bit_out <= '0';
            when conv_word(35, stm'length) =>
              ack_err <= siod_io;
            when conv_word(36, stm'length) =>
              bit_out <= '0';

                                        -- Stop transaction.
            when conv_word(37, stm'length) =>
              sccb_stm_clk <= '0';
            when conv_word(38, stm'length) =>
              sccb_stm_clk <= '1';
            when conv_word(39, stm'length) =>
              bit_out <= '1';

                                        -- Start read transaction. At this point register address has been set in prev write transaction.  
            when conv_word(40, stm'length) =>
              sccb_stm_clk <= '1';
            when conv_word(41, stm'length) =>
              bit_out <= '0';
            when conv_word(42, stm'length) =>
              sccb_stm_clk <= '0';

                                        -- Write device`s ID address.
            when conv_word(43, stm'length) =>
              bit_out <= addr_i(7);
            when conv_word(44, stm'length) =>
              bit_out <= addr_i(6);
            when conv_word(45, stm'length) =>
              bit_out <= addr_i(5);
            when conv_word(46, stm'length) =>
              bit_out <= addr_i(4);
            when conv_word(47, stm'length) =>
              bit_out <= addr_i(3);
            when conv_word(48, stm'length) =>
              bit_out <= addr_i(2);
            when conv_word(49, stm'length) =>
              bit_out <= addr_i(1);
            when conv_word(50, stm'length) =>
              bit_out <= '1';
            when conv_word(51, stm'length) =>
              bit_out <= '0';
            when conv_word(52, stm'length) =>
              ack_err <= siod_io;
            when conv_word(53, stm'length) =>
              bit_out <= '0';

                                        -- Read register value. This concludes 2-phase read transaction.
            when conv_word(54, stm'length) =>
              bit_out <= '0';
            when conv_word(55, stm'length) =>
              data_o(7) <= siod_io;
            when conv_word(56, stm'length) =>
              data_o(6) <= siod_io;
            when conv_word(57, stm'length) =>
              data_o(5) <= siod_io;
            when conv_word(58, stm'length) =>
              data_o(4) <= siod_io;
            when conv_word(59, stm'length) =>
              data_o(3) <= siod_io;
            when conv_word(60, stm'length) =>
              data_o(2) <= siod_io;
            when conv_word(61, stm'length) =>
              data_o(1) <= siod_io;
            when conv_word(62, stm'length) =>
              data_o(0) <= siod_io;
            when conv_word(63, stm'length) =>
              bit_out <= '1';
            when conv_word(64, stm'length) =>
              bit_out <= '0';
              
            when conv_word(65, stm'length) =>
              sccb_stm_clk <= '0';
            when conv_word(66, stm'length) =>
              sccb_stm_clk <= '1';
            when conv_word(67, stm'length) =>
              bit_out <= '1';
              done    <= '1';
              stm     <= (others => '0');
              
            when others =>
              sccb_stm_clk <= '1';
          end case;
        else
          sccb_stm_clk <= '1';
          bit_out      <= '1';
          done         <= '0';
          ack_err      <= '1';
        end if;
      end if;
    end if;
  end process;
  
end architecture;
