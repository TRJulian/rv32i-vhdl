--------------------------------------------------------------------------------
-- alu_pkg.vhd -- Package for alu module "alu.vhd" & its testbench "alu_tb.vhd"
--------------------------------------------------------------------------------

package alu_pkg is

  type alu_op_t is (OP_ADD, OP_SUB, OP_SLL, OP_XOR, OP_SRL, OP_SRA, OP_OR, OP_AND);

  constant SHAMT_WIDTH : positive := 5;

  subtype alu_width_t is positive range SHAMT_WIDTH to positive'high;

end package alu_pkg;
