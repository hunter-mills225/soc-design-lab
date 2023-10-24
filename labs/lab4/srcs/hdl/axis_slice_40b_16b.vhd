----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/18/2023 09:35:23 AM
-- Design Name: 
-- Module Name: axis_slice_40b_16b - Behavioral
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

entity axis_slice_40b_16b is
port(
  clk           : in std_logic;
  resetn        : in std_logic;
  s_axis_data_tdata  : in std_logic_vector(39 downto 0);
  s_axis_data_tvalid : in std_logic;
  m_axis_data_tdata  : out std_logic_vector(15 downto 0);
  m_axis_data_tvalid : out std_logic
);
end axis_slice_40b_16b;

architecture Behavioral of axis_slice_40b_16b is

--! This signal defines the highest bit from the input axis
signal HIGH_BIT : integer := 33;
begin

slice_p : process(clk)
begin
  if rising_edge(clk) then
    if resetn = '0' then
      m_axis_data_tdata  <= (others => '0');
      m_axis_data_tvalid <= '0';
    else
      m_axis_data_tvalid <= s_axis_data_tvalid;
      m_axis_data_tdata  <= s_axis_data_tdata(HIGH_BIT downto HIGH_BIT-15);
    end if;
  end if;
end process;

end Behavioral;
