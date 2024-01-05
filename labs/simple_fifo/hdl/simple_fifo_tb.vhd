---------------------------------------------------------------------------------------------------
--! @file     simple_fifo_tb.vhd
--! @author   Hunter Mills
--! @brief    Test Bench for simple_fifo
---------------------------------------------------------------------------------------------------

-- Standard Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- User Libraries
use work.all;

--! Empty TB entity
entity simple_fifo_tb is 
end simple_fifo_tb;

architecture tb of simple_fifo_tb is
  -- ------------------------------------------------
  -- Signal Assignments
  -- ------------------------------------------------
  --! Entity Signals
  signal resetn             : std_logic := '1';
  signal clk125             : std_logic := '0';
  signal s_axis_fifo_tdata  : std_logic_vector(31 downto 0);
  signal s_axis_fifo_tvalid : std_logic;
  signal s_axis_fifo_tready : std_logic;
  signal read_en            : std_logic := '0';
  signal m_axis_fifo_tdata  : std_logic_vector(31 downto 0);
  signal m_axis_fifo_tvalid : std_logic;
  signal fifo_count         : std_logic_vector(31 downto 0);

  --! TB Signals
  signal input_fifo_count : unsigned(31 downto 0) := (others => '0');
  signal pulse50          : std_logic := '0';
  signal read_flag        : std_logic := '0';
  

begin

  -- ------------------------------------------------
  -- Entity Instantiation
  -- ------------------------------------------------
  UUT : entity simple_fifo
  port map(
    clk                 => clk125,
    resetn              => resetn,
    s_axis_fifo_tdata   => s_axis_fifo_tdata,
    s_axis_fifo_tvalid  => s_axis_fifo_tvalid,
    s_axis_fifo_tready  => s_axis_fifo_tready,
    read_en             => read_en,
    m_axis_fifo_tdata   => m_axis_fifo_tdata,
    m_axis_fifo_tvalid  => m_axis_fifo_tvalid,
    fifo_count          => fifo_count
  );

  --! Create 125MHz clock
  clk125  <= not(clk125) after 4 ns;

  --! Create 50MHz pulse
  pulse50 <= not(pulse50) after 10 ns;

  --! Deassert resetn
  resetn  <= '0', '1' after 20 ns;

  fill_fifo_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '0' then
        s_axis_fifo_tdata   <= (others => '0');
        s_axis_fifo_tvalid  <= '0';
        input_fifo_count    <= (others => '0');
      elsif input_fifo_count < 100 and s_axis_fifo_tready = '1' then
        s_axis_fifo_tdata   <= std_logic_vector(input_fifo_count);
        s_axis_fifo_tvalid  <= '1';
        input_fifo_count    <= input_fifo_count + 1;
      else
        s_axis_fifo_tvalid <= '0';
      end if;
    end if;
  end process;
  
  set_flag_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '0' then
        read_flag <= '0';
      elsif input_fifo_count = 99 then
        read_flag <= '1';
      end if;
    end if;
  end process;

  read_en <= read_flag and pulse50;

end tb;