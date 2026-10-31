// The pool is passed explicitly, like a Zig allocator.
const std = @import("std");

const BinOp = enum { add, sub, mul, div };
const ExprRef = enum(u32) { _ };
const Expr = union(enum) {
    binary: struct { op: BinOp, lhs: ExprRef, rhs: ExprRef },
    literal: i64,
};

const ExprPool = struct {
    exprs: std.ArrayList(Expr) = .empty,
    gpa: std.mem.Allocator,

    fn add(p: *ExprPool, expr: Expr) ExprRef {
        p.exprs.append(p.gpa, expr) catch @panic("OOM");
        return @enumFromInt(p.exprs.items.len - 1);
    }
    fn get(p: *const ExprPool, expr: ExprRef) Expr {
        return p.exprs.items[@intFromEnum(expr)];
    }
    fn interp(p: *const ExprPool, expr: ExprRef) i64 {
        return switch (p.get(expr)) {
            .binary => |b| {
                const lhs = p.interp(b.lhs);
                const rhs = p.interp(b.rhs);
                return switch (b.op) {
                    .add => lhs +% rhs,
                    .sub => lhs -% rhs,
                    .mul => lhs *% rhs,
                    .div => if (rhs == 0) 0 else @divTrunc(lhs, rhs),
                };
            },
            .literal => |num| num,
        };
    }
    fn lit(p: *ExprPool, n: i64) ExprRef {
        return p.add(.{ .literal = n });
    }
    fn bin(p: *ExprPool, op: BinOp, lhs: ExprRef, rhs: ExprRef) ExprRef {
        return p.add(.{ .binary = .{ .op = op, .lhs = lhs, .rhs = rhs } });
    }
};

pub fn main() void {
    const gpa = std.heap.page_allocator;
    var a: ExprPool = .{ .gpa = gpa };
    const e = a.bin(.div, a.bin(.mul, a.bin(.sub, a.lit(7), a.lit(10)), a.lit(7)), a.lit(2));
    std.debug.print("{d}\n", .{a.interp(e)});
    {
        var b: ExprPool = .{ .gpa = gpa };
        std.debug.print("{d}\n", .{b.interp(b.bin(.div, b.bin(.add, b.lit(4), b.lit(4)), b.bin(.sub, b.lit(4), b.lit(4))))});
    }
    std.debug.print("{d}\n", .{a.interp(e)});
}
