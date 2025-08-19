library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA is
  generic(
    sync_polarity : std_logic := '1'
     );
  port(
       i_clk50: in std_logic;
       o_red:   out std_logic;
       o_green: out std_logic;
       o_blue:  out std_logic;
       o_hs:    out std_logic;
       o_vs:    out std_logic
     );
end VGA;

architecture Behavioral of VGA is
  signal clk25             : std_logic;
  signal hs : natural := 0;
  signal vs : natural := 0;

  signal red : std_logic := '0';
  signal green : std_logic := '0';
  signal blue : std_logic := '0';

  -- Colour is currently writable to the display
  signal is_addressable : std_logic := '0';

  -- Horizontal sync res
  constant H_RES : natural         := 640;
  constant H_FRONT_PORCH : natural := 16;
  constant H_BACK_PORCH : natural  := 48;
  constant H_SYNC_PULSE : natural  := 96;
  constant H_CYCLES : natural      := H_RES + H_FRONT_PORCH + H_BACK_PORCH + H_SYNC_PULSE;

  constant V_RES : natural         := 480;
  constant V_FRONT_PORCH : natural := 10;
  constant V_BACK_PORCH : natural  := 33;
  constant V_SYNC_PULSE : natural  := 2;
  constant V_CYCLES : natural      := V_RES + V_FRONT_PORCH + V_BACK_PORCH + V_SYNC_PULSE;

begin

  -- Output gating if in addressable area.
  o_red <= red when is_addressable = '1' else '0';
  o_green <= green when is_addressable = '1' else '0';
  o_blue <= blue when is_addressable = '1' else '0';

  is_addressable <= '1' when
    vs < V_RES and
    hs < H_RES else '0';

  -- generate a 25Mhz clock
  process (i_clk50)
  begin
    if rising_edge(i_clk50) then
      if (clk25 = '0') then              
        clk25 <= '1';
      else
        clk25 <= '0';
      end if;
    end if;
  end process;

  process (clk25)
  begin
    if rising_edge(clk25) then
      -- Background colour
      red <= '0';
      green <= '0';
      blue <= '0';
      if (  hs > H_RES / 2 - 200
        and hs < H_RES / 2 + 200
        and vs > V_RES / 2 - 200
        and vs < V_RES / 2 + 200
      ) then
        red <= '1';
      end if;

      -- Horizontal Sync Pulse
      if (hs < H_RES + H_FRONT_PORCH or hs > H_RES + H_FRONT_PORCH + H_SYNC_PULSE) then
        o_hs <= sync_polarity;
      else
        o_hs <= not sync_polarity;
      end if;
      
      -- Vertical Sync Pulse
      if (vs < V_RES + V_FRONT_PORCH or vs > V_RES + V_FRONT_PORCH + V_SYNC_PULSE) then
        o_vs <= sync_polarity;
      else
        o_vs <= not sync_polarity;
      end if;

      hs <= hs + 1;
      if ( hs = H_CYCLES ) then
        vs <= vs + 1;
        hs <= 0;
      end if;
      if (vs = V_CYCLES) then                 
        vs <= 0;
      end if;
    end if;
  end process;
end Behavioral;
