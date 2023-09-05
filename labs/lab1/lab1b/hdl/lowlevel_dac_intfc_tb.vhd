---------------------------------------------------------------------------------------------------
--! @file     lowlevel_dac_intfc_tb.vhd
--! @author   Hunter Mills
--! @brief    Test Bench for lowlevel_dac_intfc
---------------------------------------------------------------------------------------------------

-- Standard Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- User Libraries
use work.all;

--! Empty TB entity
entity lowlevel_dac_intfc_tb is 
end lowlevel_dac_intfc_tb;

architecture tb of lowlevel_dac_intfc_tb is
  -- ------------------------------------------------
  -- Signal Assignments
  -- ------------------------------------------------
  --! Entity Signals
  signal resetn       : std_logic := '1';
  signal clk125       : std_logic := '0';
  signal data_word    : std_logic_vector(31 downto 0) := "00001111001111001111000011000011";
  signal sdata        : std_logic;
  signal lrck         : std_logic;
  signal bclk         : std_logic;
  signal mclk         : std_logic;
  signal latched_data : std_logic;

begin

  -- ------------------------------------------------
  -- Entity Instantiation
  -- ------------------------------------------------
  UUT : entity lowlevel_dac_intfc
  port map(
    resetn        => resetn,
    clk125        => clk125,
    data_word     => data_word,
    sdata         => sdata,
    lrck          => lrck,
    bclk          => bclk,
    mclk          => mclk,
    latched_data  => latched_data
  );

  --! Create 125MHz clock
  clk125  <= not(clk125) after 4 ns;
  --! Deassert resetn
  resetn  <= '1', '0' after 20 ns;

  lowlevel_dac_intfc_tb_p : process
  begin
    wait until latched_data = '1';
    data_word <= (others => '1');
    wait until latched_data = '1';
    data_word <= (others => '0');
    wait;
  end process;

end tb;