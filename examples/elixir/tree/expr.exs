# The tree Sampson starts from: each node is a tuple holding its children, so
# nothing needs a pool; nodes are immutable terms on the process heap.
defmodule Expr do
  # An expression is {:binary, op, lhs, rhs} or {:literal, num}.
  def interp(expr) do
    case expr do
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

  def lit(n), do: {:literal, n}
  def bin(op, l, r), do: {:binary, op, l, r}

  def main do
    e = bin(:div, bin(:mul, bin(:sub, lit(7), lit(10)), lit(7)), lit(2))
    IO.puts(interp(e))

    IO.puts(interp(bin(:div, bin(:add, lit(4), lit(4)), bin(:sub, lit(4), lit(4)))))

    IO.puts(interp(e))
  end
end

Expr.main()
