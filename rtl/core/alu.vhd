--------------------------------------------------------------------------------
-- alu.vhd -- RV32I integer ALU
--
-- Purely combinational. Computes one of the 8 RV32I ALU operations selected
-- by alu_op_i. The shift amount is the low 5 bits of src_b_i, per RV32I.
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.alu_pkg.all;

entity alu is
  generic (
    WIDTH : alu_width_t := 32
  );
  port (
    alu_op_i  : in    alu_op_t;
    src_a_i   : in    std_logic_vector(WIDTH - 1 downto 0);
    src_b_i   : in    std_logic_vector(WIDTH - 1 downto 0);
    alu_res_o : out   std_logic_vector(WIDTH - 1 downto 0)
  );
end entity alu;

architecture rtl of alu is

begin

  with alu_op_i select alu_res_o <=
    std_logic_vector(signed(src_a_i) + signed(src_b_i)) when OP_ADD,
    std_logic_vector(signed(src_a_i) - signed(src_b_i)) when OP_SUB,
    std_logic_vector(shift_left(unsigned(src_a_i),
        to_integer(unsigned(src_b_i(SHAMT_WIDTH - 1 downto 0))))) when OP_SLL,
    src_a_i xor src_b_i when OP_XOR,
    std_logic_vector(shift_right(unsigned(src_a_i),
        to_integer(unsigned(src_b_i(SHAMT_WIDTH - 1 downto 0))))) when OP_SRL,
    std_logic_vector(shift_right(signed(src_a_i),
        to_integer(unsigned(src_b_i(SHAMT_WIDTH - 1 downto 0))))) when OP_SRA,
    src_a_i or src_b_i when OP_OR,
    src_a_i and src_b_i when OP_AND;

end architecture rtl;
