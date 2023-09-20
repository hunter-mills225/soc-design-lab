---------------------------------------------------------------------------------------------------
--! @file     toplevel_tb.vhd
--! @author   Hunter Mills
--! @brief    Top Level Testbench for LED lab
--! @details  Drive LED's at 2Hz
---------------------------------------------------------------------------------------------------

-- Standard Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_toplevel is
end tb_toplevel;

architecture tb of tb_toplevel is
  component toplevel
  port(
    reset_pb : in std_logic;
    sysclk : in std_logic;
    led : out std_logic_vector (3 downto 0));
  end component;

  signal reset_pb   : std_logic;
  signal clk_in     : std_logic;
  signal led        : std_logic_vector (3 downto 0);
  constant TbPeriod : time := 8 ns;
  signal TbClock    : std_logic := '0';

begin
  dut : toplevel
  port map(
    reset_pb  => reset_pb,
    sysclk    => clk_in,
    led       => led
  );

  TbClock   <= not TbClock after TbPeriod/2;
  clk_in    <= TbClock;
  stimuli : process
  begin
    reset_pb <= '1';
    wait for 232 ns;
    reset_pb <= '0';
  wait;
  end process;

end tb;
