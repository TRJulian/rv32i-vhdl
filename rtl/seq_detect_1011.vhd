library ieee;
  use ieee.std_logic_1164.all;

entity seq_detect_1011 is
  port (
    clk_i   : in    std_logic;
    rst_i   : in    std_logic;
    d_i     : in    std_logic;
    match_o : out   std_logic
  );
end entity seq_detect_1011;

architecture rtl of seq_detect_1011 is

  type state_t is (ST_IDLE, ST_1, ST_10, ST_101);

  signal state_r : state_t;

begin

  detect_reg_proc : process (clk_i) is
  begin

    if (rising_edge(clk_i)) then
      if (rst_i = '1') then
        state_r <= ST_IDLE;
        match_o <= '0';
      else

        case state_r is

          when ST_IDLE =>

            match_o <= '0';

            if (d_i = '1') then
              state_r <= ST_1;
            end if;

          when ST_1 =>

            match_o <= '0';

            if (d_i = '0') then
              state_r <= ST_10;
            end if;

          when ST_10 =>

            match_o <= '0';

            if (d_i = '1') then
              state_r <= ST_101;
            else
              state_r <= ST_IDLE;
            end if;

          when ST_101 =>

            if (d_i = '1') then
              state_r <= ST_1;
              match_o <= '1';
            else
              state_r <= ST_10;
            /* match_o is deliberately not assigned, as ST_101 is only ever reached from ST_10 which already drives 
            * match_o to '0' . */
            end if;

        end case;

      end if;
    end if;

  end process detect_reg_proc;

end architecture rtl;
