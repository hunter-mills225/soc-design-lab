----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/12/2023 07:00:24 PM
-- Design Name: 
-- Module Name: simple_fifo_counter - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity simple_fifo_counter is
    Port ( clk : in STD_LOGIC;
           resetn : in STD_LOGIC;
           m_axis_tdata : out STD_LOGIC_VECTOR (31 downto 0);
           m_axis_tvalid : out STD_LOGIC);
end simple_fifo_counter;

architecture Behavioral of simple_fifo_counter is
signal freq_counter : unsigned(31 downto 0);
signal counter : unsigned(31 downto 0);

begin

freq_counter_p : process(clk)
begin
  if rising_edge(clk) then
    if resetn = '0' then
      freq_counter <= (others => '0');
    elsif freq_counter < 2560 then
      freq_counter <= freq_counter + 1;
    else
      freq_counter <= (others => '0');
    end if;
  end if;
end process;

counter_p : process(clk)
begin
  if rising_edge(clk) then
    if resetn = '0' then
      m_axis_tvalid <= '0';
      counter <= (others => '0');
    elsif freq_counter = 2559 then
      counter <= counter + 1;
      m_axis_tvalid <= '1';
    else
      m_axis_tvalid <= '0';
    end if;
  end if;
end process;
m_axis_tdata <= std_logic_vector(counter);
end Behavioral;
