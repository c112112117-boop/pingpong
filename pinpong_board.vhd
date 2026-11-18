
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    generic (
        DEBOUNCE_MAX : integer := 1000000;
        MOVE_MAX     : integer := 75000000
    );
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        sw_r  : in  std_logic;
        sw_l  : in  std_logic;
        led_r : out std_logic_vector(7 downto 0)
    );
end top;

architecture Behavioral of top is

    type game_state is (
        MOVE_RIGHT,
        WAIT_RIGHT,
        MOVE_LEFT,
        WAIT_LEFT,
        ROUND_OVER
    );

    signal state : game_state := MOVE_RIGHT;

    signal position : integer range 0 to 7 := 0;

    signal move_count : integer range 0 to MOVE_MAX-1 := 0;
    signal move_tick  : std_logic := '0';

    -- Button synchronizers
    signal r_sync1, r_sync2 : std_logic := '0';
    signal l_sync1, l_sync2 : std_logic := '0';

    -- Button debounce
    signal r_count : integer range 0 to DEBOUNCE_MAX := 0;
    signal l_count : integer range 0 to DEBOUNCE_MAX := 0;

    signal r_pressed : std_logic := '0';
    signal l_pressed : std_logic := '0';

    signal r_old : std_logic := '0';
    signal l_old : std_logic := '0';

    signal r_click : std_logic := '0';
    signal l_click : std_logic := '0';

    -- Scores
    signal right_score : unsigned(3 downto 0)
                       := (others => '0');

    signal left_score : unsigned(3 downto 0)
                      := (others => '0');

begin

    ------------------------------------------------
    -- Button Synchronizer
    ------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            r_sync1 <= '0';
            r_sync2 <= '0';
            l_sync1 <= '0';
            l_sync2 <= '0';

        elsif rising_edge(clk) then
            r_sync1 <= sw_r;
            r_sync2 <= r_sync1;

            l_sync1 <= sw_l;
            l_sync2 <= l_sync1;
        end if;
    end process;


    ------------------------------------------------
    -- Button Debounce and One-Shot Pulse
    ------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            r_count <= 0;
            l_count <= 0;

            r_pressed <= '0';
            l_pressed <= '0';

            r_old <= '0';
            l_old <= '0';

            r_click <= '0';
            l_click <= '0';

        elsif rising_edge(clk) then

            r_click <= '0';
            l_click <= '0';

            -- Right button
            if r_sync2 = '1' then
                if r_count < DEBOUNCE_MAX then
                    r_count <= r_count + 1;
                else
                    r_pressed <= '1';
                end if;
            else
                r_count <= 0;
                r_pressed <= '0';
            end if;

            -- Left button
            if l_sync2 = '1' then
                if l_count < DEBOUNCE_MAX then
                    l_count <= l_count + 1;
                else
                    l_pressed <= '1';
                end if;
            else
                l_count <= 0;
                l_pressed <= '0';
            end if;

            -- Rising edge detection
            if r_pressed = '1' and r_old = '0' then
                r_click <= '1';
            end if;

            if l_pressed = '1' and l_old = '0' then
                l_click <= '1';
            end if;

            r_old <= r_pressed;
            l_old <= l_pressed;

        end if;
    end process;


    ------------------------------------------------
    -- Clock Enable: LED Movement Timer
    ------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            move_count <= 0;
            move_tick <= '0';

        elsif rising_edge(clk) then

            move_tick <= '0';

            if move_count = MOVE_MAX-1 then
                move_count <= 0;
                move_tick <= '1';
            else
                move_count <= move_count + 1;
            end if;

        end if;
    end process;


    ------------------------------------------------
    -- Game FSM
    ------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then

            state <= MOVE_RIGHT;
            position <= 0;

            right_score <= (others => '0');
            left_score <= (others => '0');

        elsif rising_edge(clk) then

            case state is

                ------------------------------------
                -- Move from left to right
                ------------------------------------
                when MOVE_RIGHT =>

                    if move_tick = '1' then
                        if position < 7 then
                            position <= position + 1;
                        else
                            state <= WAIT_RIGHT;
                        end if;
                    end if;


                ------------------------------------
                -- Wait for right player
                ------------------------------------
                when WAIT_RIGHT =>

                    if r_click = '1' then
                        position <= 6;
                        state <= MOVE_LEFT;

                    elsif l_click = '1' then
                        left_score <= left_score + 1;
                        state <= ROUND_OVER;

                    elsif move_tick = '1' then
                        left_score <= left_score + 1;
                        state <= ROUND_OVER;
                    end if;


                ------------------------------------
                -- Move from right to left
                ------------------------------------
                when MOVE_LEFT =>

                    if move_tick = '1' then
                        if position > 0 then
                            position <= position - 1;
                        else
                            state <= WAIT_LEFT;
                        end if;
                    end if;


                ------------------------------------
                -- Wait for left player
                ------------------------------------
                when WAIT_LEFT =>

                    if l_click = '1' then
                        position <= 1;
                        state <= MOVE_RIGHT;

                    elsif r_click = '1' then
                        right_score <= right_score + 1;
                        state <= ROUND_OVER;

                    elsif move_tick = '1' then
                        right_score <= right_score + 1;
                        state <= ROUND_OVER;
                    end if;


                ------------------------------------
                -- Round over: wait for next serve
                ------------------------------------
                when ROUND_OVER =>

                    if r_click = '1' or l_click = '1' then
                        position <= 0;
                        state <= MOVE_RIGHT;
                    end if;


                when others =>
                    state <= MOVE_RIGHT;

            end case;

        end if;
    end process;


    ------------------------------------------------
    -- LED Display
    ------------------------------------------------
    process(state, position, left_score, right_score)
    begin

        case state is

            when ROUND_OVER =>
                led_r <= std_logic_vector(left_score) &
                         std_logic_vector(right_score);

            when others =>
                led_r <= std_logic_vector(
                    shift_left(to_unsigned(1, 8), position)
                );

        end case;

    end process;

end Behavioral;
