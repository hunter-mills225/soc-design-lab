---------------------------------------------------------------------------------------------------
--! @file     lowlevel_dac_intfc.vhd
--! @author   Hunter Mills
--! @brief    Enitity to drive an external DAC
--! @details  32b Parallel to Serial converter to drive DAC
---------------------------------------------------------------------------------------------------

-- Standard Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- User Libraries

--! Entity top_level
entity lowlevel_dac_intfc is
  port(
  resetn        : in std_logic; -- active low synchronous reset
  clk125        : in std_logic; -- the clock for all flops in your design
  data_word     : in std_logic_vector(31 downto 0); -- 32 bit input data
  sdata         : out std_logic;  -- serial data out to the DAC
  lrck          : out std_logic;  -- 48.828125 kHz clock
  bclk          : out std_logic;  -- 1.5625 MHz clock
  mclk          : out std_logic;  -- 12.5MHz clock
  latched_data  : out std_logic   -- 1 clk125 wide pulse which indicates this entity is ready for next data
  );
end lowlevel_dac_intfc;

--! Architecture
architecture behav of lowlevel_dac_intfc is
  -- ------------------------------------------------
  -- Signals
  -- ------------------------------------------------

  --! Counter Signals
  signal l_cnt    : natural range 0 to 1279 := 0;
  signal b_cnt    : natural range 0 to 39   := 0;
  signal m_cnt    : natural range 0 to 4    := 0;
  signal data_cnt : unsigned(4 downto 0)    := (others => '0');

  --! Clock Signals
  signal s_lrck : std_logic;
  signal s_bclk : std_logic;
  signal s_mclk : std_logic;

  --! Register
  signal data_word_reg  : std_logic_vector(31 downto 0);
  signal latched_data_s : std_logic;

begin
  -- ------------------------------------------------
  -- Processes for counters and clk
  -- ------------------------------------------------

  --! Process for l_cnt clock
  lclk_cnt_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '1' then
        l_cnt <= 80;    -- This offset is to account for the 1 data_cnt offset, set to 0 if that is wrong
      else
        if l_cnt = 1279 then
          l_cnt <= 0;
        else
          l_cnt <= l_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  --! Process for b_cnt clock
  bclk_cnt_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '1' then
        b_cnt <= 0;
      else
        if b_cnt = 39 then
          b_cnt <= 0;
        else
          b_cnt <= b_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  --! Process for m_cnt clock
  mclk_cnt_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '1' then
        m_cnt <= 0;
      else
        if m_cnt = 4 then
          m_cnt <= 0;
        else
          m_cnt <= m_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  --! Process for data_cnt
  data_cnt_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '1' then
        data_cnt  <= (others => '1');
      else
        if s_bclk = '1' and b_cnt = 39 then
          data_cnt  <= data_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  --! Process to create lrck
  clk_lrck_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '1' then
        s_lrck  <= '0';
      else
        if l_cnt = 1279 then
          s_lrck  <= not(s_lrck);
        end if;
      end if;
    end if;
  end process;

  --! Process to create bclk
  clk_bclk_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '1' then
        s_bclk  <= '0';
      else
        if b_cnt = 39 then
          s_bclk  <= not(s_bclk);
        end if;
      end if;
    end if;
  end process;

  --! Process to create mclk
  clk_mclk_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '1' then
        s_mclk  <= '0';
      else
        if m_cnt = 4 then
          s_mclk  <= not(s_mclk);
        end if;
      end if;
    end if;
  end process;

  -- ------------------------------------------------
  -- Register Input Data for Clock Domain Crossing
  -- ------------------------------------------------
  cdc_reg_data_word_p : process(clk125)
  begin
    if rising_edge(clk125) then
      if resetn = '1' then
        data_word_reg <= (others => '0');
      elsif latched_data_s = '1' then
        data_word_reg <= data_word;
      end if;
    end if;
  end process;

  -- ------------------------------------------------
  -- Signal Assignments
  -- ------------------------------------------------
  lrck  <= s_lrck;
  bclk  <= s_bclk;
  mclk  <= s_mclk;
  sdata <= data_word_reg(to_integer(data_cnt));
  latched_data <= '1' when data_cnt = 0 and b_cnt = 39 and s_bclk = '1' else '0';
  latched_data_s  <= '1' when data_cnt = 0 and b_cnt = 39 and s_bclk = '1' else '0';

end behav;
