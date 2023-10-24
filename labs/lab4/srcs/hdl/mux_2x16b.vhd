----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/17/2023 08:32:04 PM
-- Design Name: 
-- Module Name: 2x16b_mux - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity mux_2x16b is
port(
  clk       : in std_logic;
  resetn    : in std_logic;
  sel       : in std_logic;
  input_0   : in std_logic_vector(15 downto 0);
  input_1   : in std_logic_vector(15 downto 0);
  data_out  : out std_logic_vector(15 downto 0)
);
end mux_2x16b;

architecture Behavioral of mux_2x16b is
begin

--! Mux process 
mux_p : process(clk)
begin
  if rising_edge(clk) then
    if resetn = '0' then
      data_out <= (others => '0');
    elsif sel = '0' then
      data_out <= input_0;
    elsif sel = '1' then
      data_out <= input_1;
    end if;
  end if;
end process;

end Behavioral;
