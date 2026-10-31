# The process dictionary: `Process.put` swaps in a fresh pool for a scope and
# hands back the old one to restore. The pool is immutable, so `add` puts a
# grown copy in its place.
defmodule Expr do
  def with_pool(fun) do
    outer = Process.put(:pool, :array.new())

    try do
      fun.()
    after
      Process.put(:pool, outer)
    end
  end

  def add(expr) do
    pool = Process.get(:pool)
    ref = :array.size(pool)
    Process.put(:pool, :array.set(ref, expr, pool))
    ref
  end

  def get(ref), do: :array.get(ref, Process.get(:pool))

  # An expression is {:binary, op, lhs, rhs} or {:literal, num}; an ExprRef is its index.
  def interp(ref) do
    case get(ref) do
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

  def main do
    with_pool(fn ->
      e = bin(:div, bin(:mul, bin(:sub, lit(7), lit(10)), lit(7)), lit(2))
      IO.puts(interp(e))

      with_pool(fn ->
        IO.puts(interp(bin(:div, bin(:add, lit(4), lit(4)), bin(:sub, lit(4), lit(4)))))
      end)

      IO.puts(interp(e))
    end)
  end
end

Expr.main()
