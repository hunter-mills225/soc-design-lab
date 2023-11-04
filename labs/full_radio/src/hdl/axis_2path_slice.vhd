----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/26/2023 07:37:44 PM
-- Design Name: 
-- Module Name: axis_2path_slice - Behavioral
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

entity axis_2path_slice is
port(
  clk           : in STD_LOGIC;
  resetn        : in STD_LOGIC;
  s_axis_tdata  : in STD_LOGIC_VECTOR (79 downto 0);
  s_axis_tvalid : in STD_LOGIC;
  m_axis_tdata  : out STD_LOGIC_VECTOR (31 downto 0);
  m_axis_tvalid : out STD_LOGIC);
end axis_2path_slice;

architecture Behavioral of axis_2path_slice is

--! Axis Reg Signals
signal axis_real_tdata  : std_logic_vector(39 downto 0);
signal axis_imag_tdata  : std_logic_vector(39 downto 0);
signal axis_valid_s     : std_logic;

begin

  --! Split Complex AXIS into real and imag parts
  split_iq_p : process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        axis_real_tdata <= (others => '0');
        axis_imag_tdata <= (others => '0');
        axis_valid_s    <= '0';
      else
        axis_real_tdata <= s_axis_tdata(39 downto 0);
        axis_imag_tdata <= s_axis_tdata(79 downto 40);
        axis_valid_s    <= s_axis_tvalid;
      end if;
    end if;
  end process;

  --! Slice both AXIS to scale and cat the outputs into one AXIS stream
  slice_p : process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        m_axis_tdata  <= (others => '0');
        m_axis_tvalid <= '0';
      else
        m_axis_tdata <= axis_imag_tdata(32 downto 17) & axis_real_tdata(32 downto 17);
        m_axis_tvalid  <= axis_valid_s;
      end if;
    end if;
  end process;

end Behavioral;
