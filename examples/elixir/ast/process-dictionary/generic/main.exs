# Protocol: the process dictionary holds any value implementing `Ast`, and its
# references can be anything at all. Values are immutable, so `Ast.add` has to
# return the grown pool alongside the ref, for `add` to put back.
defprotocol Ast do
  def add(ast, expr)
  def get(ast, ref)
end

defmodule Expr do
  def with_ast(ast, fun) do
    outer = Process.put(:ast, ast)

    try do
      fun.()
    after
      Process.put(:ast, outer)
    end
  end

  defp add(expr) do
    {ref, ast} = Ast.add(Process.get(:ast), expr)
    Process.put(:ast, ast)
    ref
  end

  # An expression is {:binary, op, lhs, rhs} or {:literal, num}; lhs and rhs are refs.
  def interp(ref) do
    case Ast.get(Process.get(:ast), ref) do
      {:binary, op, lhs, rhs} ->
        {l, r} = {interp(lhs), interp(rhs)}

        case op do
          :add -> l + r
          :sub -> l - r
          :mul -> l * r
          :div -> if r == 0, do: 0, else: div(l, r)
        end

      {:literal, num} ->
        num
    end
  end

  def lit(n), do: add({:literal, n})
  def bin(op, l, r), do: add({:binary, op, l, r})

  @ops [:add, :sub, :mul, :div]
  @codes Map.new(Enum.with_index(@ops, 1))

  # A node as three ints: 0 for a literal (num second), else 1..4 for its op.
  def encode({:binary, op, l, r}, int), do: {@codes[op], int.(l), int.(r)}
  def encode({:literal, num}, _int), do: {0, num, 0}

  def decode({0, num, _}, _ref), do: {:literal, num}
  def decode({op, l, r}, ref), do: {:binary, Enum.at(@ops, op - 1), ref.(l), ref.(r)}
end

# Representation 1: a node is an index into parallel lists.
defmodule Idx do
  defstruct [:i]
end

defmodule Columns do
  defstruct ops: :array.new(), lhs: :array.new(), rhs: :array.new()
end

defimpl Ast, for: Columns do
  def add(%Columns{ops: ops, lhs: lhs, rhs: rhs}, expr) do
    {op, l, r} = Expr.encode(expr, & &1.i)
    i = :array.size(ops)

    columns = %Columns{
      ops: :array.set(i, op, ops),
      lhs: :array.set(i, l, lhs),
      rhs: :array.set(i, r, rhs)
    }

    {%Idx{i: i}, columns}
  end

  def get(%Columns{ops: ops, lhs: lhs, rhs: rhs}, %Idx{i: i}) do
    Expr.decode({:array.get(i, ops), :array.get(i, lhs), :array.get(i, rhs)}, &%Idx{i: &1})
  end
end

# Representation 2: a node is an index into one list of triples.
defmodule Slot do
  defstruct [:i]
end

defmodule Triples do
  defstruct triples: :array.new()
end

defimpl Ast, for: Triples do
  def add(%Triples{triples: triples}, expr) do
    {op, l, r} = Expr.encode(expr, & &1.i)
    n = :array.size(triples)
    triples = Enum.reduce([op, l, r], triples, &:array.set(:array.size(&2), &1, &2))
    {%Slot{i: div(n, 3)}, %Triples{triples: triples}}
  end

  def get(%Triples{triples: triples}, %Slot{i: i}) do
    [op, l, r] = for j <- (3 * i)..(3 * i + 2), do: :array.get(j, triples)
    Expr.decode({op, l, r}, &%Slot{i: &1})
  end
end

defmodule Main do
  import Expr

  def main do
    with_ast(%Columns{}, fn ->
      e = bin(:div, bin(:mul, bin(:sub, lit(7), lit(10)), lit(7)), lit(2))
      IO.puts(interp(e))

      with_ast(%Triples{}, fn ->
        IO.puts(interp(bin(:div, bin(:add, lit(4), lit(4)), bin(:sub, lit(4), lit(4)))))
      end)

      IO.puts(interp(e))
    end)
  end
end

Main.main()
