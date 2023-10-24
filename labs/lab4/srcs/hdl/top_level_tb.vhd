----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/25/2023 10:04:47 AM
-- Design Name: 
-- Module Name: top_level_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use STD.textio.all;

use work.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_level_tb is
end top_level_tb;

architecture Behavioral of top_level_tb is
  
  signal clk125 : std_logic := '0';
  signal counter : integer := 0;
  signal resetn : std_logic;
  signal output_data : std_logic_vector(15 downto 0);
  signal output_valid : std_logic;
  signal phase_inc_data : std_logic_vector(31 downto 0) := "00000000000000001101000110110111";
  signal phase_inc_valid : std_logic := '1';
  
  file sim_dds_out : text open write_mode is "./../../../../../../../srcs/matlab/simulated_sig_gen.txt";
  
begin
  --! Create 125MHz clock
  clk125  <= not(clk125) after 4 ns;
  --! Deassert resetn
  resetn  <= '1'; --'1', '0' after 20 ns;
 
  UUT: entity top_level
     port map (
      clk125 => clk125,
      resetn => resetn,
      output_data => output_data,
      output_valid => output_valid,
      phase_inc_data => phase_inc_data,
      phase_inc_valid => phase_inc_valid
    );
  
  tb_p : process
    variable outline : line;
  begin
    wait until rising_edge(clk125);
    if output_valid = '1' and counter < 8192 then
      write(outline, to_integer(signed(output_data)));
      writeline(sim_dds_out, outline);
      report "write_data_from_sig_proc: wrote" severity NOTE;
      counter <= counter + 1;
    elsif counter = 8192 then
      report "SIMULATION DONE" severity NOTE;
      phase_inc_data <= (others => '0');
      wait;
    end if;
   end process;
end Behavioral;
