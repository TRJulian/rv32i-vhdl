--------------------------------------------------------------------------------
-- cmp_tb.vhd -- Testbench for the RV32I integer comparator module "cmp.vhd"
--
-- Completes a value check using a directed operand set at default width 32,
-- and a value check using an exhaustive operand set at default width 6.
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.rv32i_pkg.all;

entity cmp_tb is
  generic (
    WIDTH_DIRECTED   : positive := 32;
    WIDTH_EXHAUSTIVE : positive := 6;
    MAX_REPORTS      : natural  := 50
  );
end entity cmp_tb;

architecture tb of cmp_tb is

  signal src_a_dir   : std_logic_vector(WIDTH_DIRECTED - 1 downto 0) := (others => '0');
  signal src_b_dir   : std_logic_vector(WIDTH_DIRECTED - 1 downto 0) := (others => '0');
  signal cmp_res_dir : std_logic;

  signal src_a_exh   : std_logic_vector(WIDTH_EXHAUSTIVE - 1 downto 0) := (others => '0');
  signal src_b_exh   : std_logic_vector(WIDTH_EXHAUSTIVE - 1 downto 0) := (others => '0');
  signal cmp_res_exh : std_logic;
  signal cmp_op      : cmp_op_t;

  type int_array_t is array (natural range <>) of integer;

  function exh_operand_set (
    w_p : positive
  ) return int_array_t is

    variable full : int_array_t(0 to 2 ** w_p - 1);

  begin

    for k in full'range loop

      full(k) := -2 ** (w_p - 1) + k;

    end loop;

    return full;

  end function exh_operand_set;

  function dir_operand_set (
    w_p : positive
  ) return int_array_t is

    variable min_s : signed(w_p - 1 downto 0);
    variable max_s : signed(w_p - 1 downto 0);

  begin

    min_s             := (others => '0');
    max_s             := (others => '1');
    min_s(min_s'high) := '1';
    max_s(max_s'high) := '0';

    return int_array_t'(to_integer(min_s), -1, 0, 1, to_integer(max_s));

  end function dir_operand_set;

  procedure check_values (
    constant w_p              : positive;
    constant operands         : int_array_t;
    variable error_counter_p  : inout natural;
    variable vector_counter_p : inout natural;

    signal src_a_p   : inout std_logic_vector;
    signal src_b_p   : inout std_logic_vector;
    signal cmp_res_p : in std_logic;
    signal cmp_op_p  : inout cmp_op_t
  ) is

    variable failed   : boolean;
    variable expected : std_logic;

  begin

    for op in cmp_op_t loop

      for a_idx in operands'range loop

        for b_idx in operands'range loop

          failed           := false;
          vector_counter_p := vector_counter_p + 1;

          cmp_op_p <= op;
          src_a_p  <= std_logic_vector(to_signed(operands(a_idx), w_p));
          src_b_p  <= std_logic_vector(to_signed(operands(b_idx), w_p));
          wait for 1 ns;

          case op is

            when CMP_EQ =>

              expected := '1' when (src_a_p = src_b_p) else '0';

            when CMP_NE =>

              expected := '1' when (src_a_p /= src_b_p) else '0';

            when CMP_LT =>

              expected := '1' when (signed(src_a_p) < signed(src_b_p)) else '0';

            when CMP_GE =>

              expected := '1' when (signed(src_a_p) >= signed(src_b_p)) else '0';

            when CMP_LTU =>

              expected := '1' when (unsigned(src_a_p) < unsigned(src_b_p)) else '0';

            when CMP_GEU =>

              expected := '1' when (unsigned(src_a_p) >= unsigned(src_b_p)) else '0';

          end case;

          if (cmp_res_p /= expected) then
            failed := true;
          end if;

          if (failed) then
            error_counter_p := error_counter_p + 1;
            if (error_counter_p <= MAX_REPORTS) then
              report "fail width=" & integer'image(w_p)
                     & ", cmp_op=" & cmp_op_t'image(op)
                     & ", src_a=" & to_string(operands(a_idx))
                     & ", src_b=" & to_string(operands(b_idx))
                     & ", expected=" & to_string(expected)
                     & ", got=" & to_string(cmp_res_p)
                severity error;
            elsif (error_counter_p = MAX_REPORTS + 1) then
              report "further failures suppressed..."
                severity note;
            end if;
          end if;

        end loop;

      end loop;

    end loop;

  end procedure check_values;

begin

  u_cmp_dir : entity work.cmp(rtl)
    generic map (
      WIDTH => WIDTH_DIRECTED
    )
    port map (
      src_a_i   => src_a_dir,
      src_b_i   => src_b_dir,
      cmp_op_i  => cmp_op,
      cmp_res_o => cmp_res_dir
    );

  u_cmp_exh : entity work.cmp(rtl)
    generic map (
      WIDTH => WIDTH_EXHAUSTIVE
    )
    port map (
      src_a_i   => src_a_exh,
      src_b_i   => src_b_exh,
      cmp_op_i  => cmp_op,
      cmp_res_o => cmp_res_exh
    );

  stim_proc : process is

    variable error_counter  : natural;
    variable vector_counter : natural;

  begin

    error_counter  := 0;
    vector_counter := 0;

    check_values(w_p              => WIDTH_DIRECTED,
                 operands         => dir_operand_set(WIDTH_DIRECTED),
                 src_a_p          => src_a_dir,
                 src_b_p          => src_b_dir,
                 cmp_res_p        => cmp_res_dir,
                 cmp_op_p         => cmp_op,
                 error_counter_p  => error_counter,
                 vector_counter_p => vector_counter);

    check_values(w_p              => WIDTH_EXHAUSTIVE,
                 operands         => exh_operand_set(WIDTH_EXHAUSTIVE),
                 src_a_p          => src_a_exh,
                 src_b_p          => src_b_exh,
                 cmp_res_p        => cmp_res_exh,
                 cmp_op_p         => cmp_op,
                 error_counter_p  => error_counter,
                 vector_counter_p => vector_counter);

    if (error_counter = 0) then
      report "pass: all " & integer'image(vector_counter) & " vectors"
        severity note;
    else
      report integer'image(error_counter) & " failures"
        severity error;
    end if;

    wait;

  end process stim_proc;

end architecture tb;
