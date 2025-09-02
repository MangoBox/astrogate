-- author: Furkan Cayci, 2018
-- description: serializer for for 10-bit tmds signal

library ieee;
use ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.all;

entity serializer is
    port (
        rst      : in  std_logic;
        -- Pixel clock @ 25MHz
        pixclk   : in  std_logic;  -- low speed pixel clock 1x
        pixel_in : in  std_logic_vector(9 downto 0);
        -- Serial clock @ 125Mhz
        -- DDR'd to 250MHz
        serclk   : in  std_logic;  -- high speed serial clock 5x
        s_p  : out std_logic;   -- 250MHz DDR out
        load : in std_logic
    );
end serializer;

architecture rtl of serializer is
  signal shift_reg   : std_logic_vector(9 downto 0) := (others => '0');
  signal bit_count   : integer range 0 to 4 := 0;
  signal datain_h    : std_logic := '0';  -- Rising edge data
  signal datain_l    : std_logic := '0';  -- Falling edge data

  -- Load strobe sync
  signal load_sync   : std_logic := '0';
  signal load_pulse  : std_logic := '0';


  signal serial_out  : std_logic := '0';
begin

  -- Quartus should synth n differential pair
  s_p <= serial_out;

   -- Detect rising edge of load (sync'd to clk_25)
  process(pixclk)
  begin
    if rising_edge(pixclk) then
      if rst = '1' then
        load_sync  <= '0';
        load_pulse <= '0';
      else
        load_pulse <= load and not load_sync;
        load_sync  <= load;
      end if;
    end if;
  end process;

  -- Load pixel data into shift register (clk_25 domain)
  process(pixclk)
  begin
    if rising_edge(pixclk) then
      if rst = '1' then
        shift_reg <= (others => '0');
      elsif load_pulse = '1' then
        shift_reg <= pixel_in;
      end if;
    end if;
  end process;

  -- Serializer at 125 MHz (shifts 2 bits per cycle using DDR)
  process(serclk)
  begin
    if rising_edge(serclk) then
      if rst = '1' then
        datain_h <= '0';
        datain_l <= '0';
        bit_count <= 0;
      else
        datain_h <= shift_reg(9 - bit_count*2);       -- MSB first
        datain_l <= shift_reg(9 - (bit_count*2 + 1));
        
        if bit_count = 4 then
          bit_count <= 0;
        else
          bit_count <= bit_count + 1;
        end if;
      end if;
    end if;
  end process;

  -- DDR output instantiation
  altddio_out_inst : entity work.hdmi_tmds_ddr
    port map (
      datain_h(0) => datain_h,
      datain_l(0) => datain_l,
      outclock    => serclk,
      dataout(0)  => serial_out,
      aclr        => rst
    );
end rtl;
