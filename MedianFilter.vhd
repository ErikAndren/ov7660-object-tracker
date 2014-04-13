-- Implements median filter
-- Sorts all entries and selects the median value
-- Optimized comparator tree picked from
-- www.ijetae.com ISSN 2250-2459, Vol 2, Issue 8, Aug 2012. Fig 5
--
-- Copyright Erik Zachrisson - erik@zachrisson.info


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.Types.all;
use work.OV76X0Pack.all;

entity MedianFilter is
  generic (
    DataW : in positive;
    Res   : in positive
    );
  port (
    Clk         : in  bit1;
    RstN        : in  bit1;
    --
    PixelIn     : in  PixVec2d(Res-1 downto 0);
    PixelInVal  : in  bit1;
    --
    PixelOut    : out word(DataW-1 downto 0);
    PixelOutVal : out bit1
    );
end entity;

architecture rtl of MedianFilter is
  constant Threshold                  : natural := 255;
  signal PixelOut_N, PixelOut_D       : word(DataW-1 downto 0);
  signal PixelOutVal_N, PixelOutVal_D : bit1;
  signal PixelOutVal_D2 : bit1;

  procedure Comparator (signal X : in word; signal Y : in word; signal Higher : out word; signal Lower : out word) is
  begin
    if X > Y then
      Higher <= X;
      Lower  <= Y;
    else
      Higher <= Y;
      Lower  <= X;
    end if;
  end procedure;

  signal A_H, A_L, B_H, B_L, C_H, C_L, D_H, D_L, E_H, E_L, F_H, F_L : word(PixelW-1 downto 0);
  signal G_H, G_L, H_H, H_L, I_H, I_L, J_H, J_L, K_H, K_L, L_H, L_L : word(PixelW-1 downto 0);
  signal M_H, M_L, N_H, N_L, O_H, O_L, Q_H, Q_L, S_H, S_L, T_H, T_L : word(PixelW-1 downto 0);
  signal U_H, U_L, Median                                           : word(PixelW-1 downto 0);
  --
  signal J_L_D, I_H_D, K_H_D, K_L_D, I_L_D, D_L_D, L_H_D            : word(PixelW-1 downto 0);
  
begin
  A : Comparator(PixelIn(0)(0), PixelIn(0)(1), A_H, A_L);
  B : Comparator(PixelIn(1)(0), PixelIn(1)(1), B_H, B_L);
  C : Comparator(PixelIn(2)(0), PixelIn(2)(1), C_H, C_L);
  --
  D : Comparator(PixelIn(0)(2), A_L, D_H, D_L);
  E : Comparator(PixelIn(1)(2), B_L, E_H, E_L);
  F : Comparator(PixelIn(2)(2), C_L, F_H, F_L);
  --
  G : Comparator(A_H, D_H, G_H, G_L);
  H : Comparator(B_H, E_H, H_H, H_L);
  I : Comparator(C_H, F_H, I_H, I_L);
  --
  J : Comparator(G_H, H_H, J_H, J_L);
  K : Comparator(G_L, H_L, K_H, K_L);
  L : Comparator(E_L, F_L, L_H, L_L);
  --
  M : Comparator(J_L_D, I_H_D, M_H, M_L);
  N : Comparator(K_L_D, I_L_D, N_H, N_L);
  O : Comparator(D_L_D, L_H_D, O_H, O_L);
  --
  Q : Comparator(K_H_D, N_H, Q_H, Q_L);
  S : Comparator(M_L, Q_L, S_H, S_L);
  T : Comparator(S_L, O_H, T_H, T_L);
  --
  U : Comparator(S_H, T_H, U_H, U_L);  
  MedianAssign : Median <= U_L;
  
  SyncRstProc : process (Clk, RstN)
  begin
    if RstN = '0' then
      PixelOutVal_D  <= '0';
      PixelOutVal_D2 <= '0';
    elsif rising_edge(Clk) then
      PixelOutVal_D  <= PixelOutVal_N;
      PixelOutVal_D2 <= PixelOutVal_D;
    end if;
  end process;

  SyncNoRstProc : process (Clk)
  begin
    if rising_edge(Clk) then
      PixelOut_D <= PixelOut_N;
      J_L_D      <= J_L;
      I_H_D      <= I_H;
      K_H_D      <= K_H;
      K_L_D      <= K_L;
      I_L_D      <= I_L;
      D_L_D      <= D_L;
      L_H_D      <= L_H;
    end if;
  end process;
  
  AsyncProc : process (PixelIn, PixelInVal, Median)
  begin
    PixelOutVal_N <= PixelInVal;
    PixelOut_N    <= Median;
  end process;

  PixelOut    <= PixelOut_D;
  PixelOutVal <= PixelOutVal_D2;
end architecture rtl;
