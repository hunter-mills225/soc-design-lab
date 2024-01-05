---------------------------------------------------------------------------------------------------
--! @file     simple_fifo.vhd
--! @author   Hunter Mills
--! @brief    A FIFO that sends values on an async read enable
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simple_fifo is
	port (
    clk                 : in std_logic;
    resetn              : in std_logic;
    s_axis_fifo_tdata   : in std_logic_vector(31 downto 0);
    s_axis_fifo_tvalid  : in std_logic;
    s_axis_fifo_tready  : out std_logic;
    read_en             : in std_logic;
    m_axis_fifo_tdata   : out std_logic_vector(31 downto 0);
    m_axis_fifo_tvalid  : out std_logic;
    fifo_count          : out std_logic_vector(31 downto 0)
	);
end simple_fifo;

architecture arch_imp of simple_fifo is

  -- --------------------------------------------
  -- Signals
  -- --------------------------------------------
  signal m_axis_fifo_tdata_s  : std_logic_vector(31 downto 0);
  signal m_axis_fifo_tvalid_s : std_logic;
  signal rising_edge_reg0     : std_logic;
  signal rising_edge_reg1     : std_logic;
  signal rising_edge_read_en  : std_logic;

  -- --------------------------------------------
  -- Components
  -- --------------------------------------------
  COMPONENT axis_data_fifo_0
    PORT (
      s_axis_aresetn      : IN STD_LOGIC;
      s_axis_aclk         : IN STD_LOGIC;
      s_axis_tvalid       : IN STD_LOGIC;
      s_axis_tready       : OUT STD_LOGIC;
      s_axis_tdata        : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axis_tvalid       : OUT STD_LOGIC;
      m_axis_tready       : IN STD_LOGIC;
      m_axis_tdata        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      axis_rd_data_count  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) 
    );
  END COMPONENT;

begin

  -- --------------------------------------------
  -- Instantiation
  -- --------------------------------------------
  fifo0 : axis_data_fifo_0
    PORT MAP (
      s_axis_aresetn      => resetn,
      s_axis_aclk         => clk,
      s_axis_tvalid       => s_axis_fifo_tvalid,
      s_axis_tready       => s_axis_fifo_tready,
      s_axis_tdata        => s_axis_fifo_tdata,
      m_axis_tvalid       => m_axis_fifo_tvalid_s,
      m_axis_tready       => rising_edge_read_en,
      m_axis_tdata        => m_axis_fifo_tdata_s,
      axis_rd_data_count  => fifo_count
    );

  -- --------------------------------------------
  -- Logic
  -- --------------------------------------------
  --! @brief read_en rising edge detector
  rising_edge_p : process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        rising_edge_reg0  <= '0';
        rising_edge_reg1  <= '0';
      else
        rising_edge_reg0  <= read_en;
        rising_edge_reg1  <= rising_edge_reg0;
      end if;
    end if;
  end process;
  
  rising_edge_read_en <= not(rising_edge_reg1) and rising_edge_reg0;

  --! @brief Register FIFO data to send to AXI Lite
  reg_fifo_data_p : process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        m_axis_fifo_tdata   <= (others => '0');
        m_axis_fifo_tvalid  <= '0';
      elsif rising_edge_read_en = '1' then
        m_axis_fifo_tdata   <= m_axis_fifo_tdata_s;
        m_axis_fifo_tvalid  <= m_axis_fifo_tvalid_s;
      end if;
    end if;
  end process;

end arch_imp;
