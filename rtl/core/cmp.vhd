--------------------------------------------------------------------------------
-- cmp.vhd -- RV32I integer comparator
--
-- Purely combinational. Outputs one of 6 comparisons, selected by cmp_op_i,
-- serving the 6 RV32I branch instructions and SLT/SLTU.
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.rv32i_pkg.all;

entity cmp is
  generic (
    WIDTH : positive := 32
  );
  port (
    cmp_op_i  : in    cmp_op_t;
    src_a_i   : in    std_logic_vector(WIDTH - 1 downto 0);
    src_b_i   : in    std_logic_vector(WIDTH - 1 downto 0);
    cmp_res_o : out   std_logic
  );
end entity cmp;

architecture rtl of cmp is

  signal eq  : boolean;
  signal lt  : boolean;
  signal ltu : boolean;

begin

  eq  <= (src_a_i = src_b_i);
  lt  <= (signed(src_a_i) < signed(src_b_i));
  ltu <= (unsigned(src_a_i) < unsigned(src_b_i));

  comb_proc : process (all) is
  begin

    case cmp_op_i is

      when CMP_EQ =>

        cmp_res_o <= '1' when eq else '0';

      when CMP_NE =>

        cmp_res_o <= '0' when eq else '1';

      when CMP_LT =>

        cmp_res_o <= '1' when lt else '0';

      when CMP_GE =>

        cmp_res_o <= '0' when lt else '1';

      when CMP_LTU =>

        cmp_res_o <= '1' when ltu else '0';

      when CMP_GEU =>

        cmp_res_o <= '0' when ltu else '1';

    end case;

  end process comb_proc;

end architecture rtl;
