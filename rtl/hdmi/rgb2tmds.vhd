-- author: Furkan Cayci, 2018
-- description: generate tmds output based on the given rgb values and video timing
--   used for DVI and HDMI signaling

library ieee;
use ieee.std_logic_1164.all;

entity rgb2tmds is
    port(
        -- reset and clocks
        rst : in std_logic;
        pixelclock : in std_logic;  -- slow pixel clock 1x
        serialclock : in std_logic; -- fast serial clock 5x

        -- video signals
        video_data : in std_logic_vector(23 downto 0);
        video_active  : in std_logic;
        hsync : in std_logic;
        vsync : in std_logic;

        -- tmds output ports
        clk_p : out std_logic;
        data_p : out std_logic_vector(2 downto 0)
    );
end rgb2tmds;

architecture rtl of rgb2tmds is
    signal enred, engreen, enblue : std_logic_vector(9 downto 0) := (others => '0');
    signal sync : std_logic_vector(1 downto 0);

begin

    sync <= vsync & hsync;

    -- tmds encoder
    tb : entity work.tmds_encoder(rtl)
        port map (clk=>pixelclock, en=>video_active, ctrl=>sync, din=>video_data(7  downto 0), dout=>enblue);
    tr : entity work.tmds_encoder(rtl)
        port map (clk=>pixelclock, en=>video_active, ctrl=>"00", din=>video_data(23 downto 16), dout=>enred);
    tg : entity work.tmds_encoder(rtl)
        port map (clk=>pixelclock, en=>video_active, ctrl=>"00", din=>video_data(15 downto 8), dout=>engreen);

    -- tmds output serializers
    ser_b: entity work.serializer(rtl)
        port map (
           pixclk=>pixelclock,
           serclk=>serialclock,
           rst=>rst, 
           pixel_in=>enblue,
           s_p=>data_p(0),
           load=>'1'
         );

    ser_g: entity work.serializer(rtl)
        port map (
           pixclk=>pixelclock,
           serclk=>serialclock,
           rst=>rst, 
           pixel_in=>engreen,
           s_p=>data_p(1),
           load=>'1'
         );

    ser_r: entity work.serializer(rtl)
        port map (
           pixclk=>pixelclock,
           serclk=>serialclock,
           rst=>rst, 
           pixel_in=>engreen,
           s_p=>data_p(2),
           load=>'1'
         );

    -- tmds clock serializer to phase align with data signals
    ser_c: entity work.serializer(rtl)
        port map (
          pixclk=>pixelclock,
          serclk=>serialclock,
          rst=>rst,
          pixel_in=>"1111100000",
          s_p=>clk_p,
          load=> '1'
        );

end rtl;
