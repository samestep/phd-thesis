// The tree Sampson starts from: each node points to its children, so nothing
// needs a pool, but every node is its own allocation and must be freed.
const std = @import("std");

const BinOp = enum { add, sub, mul, div };
const Expr = union(enum) {
    binary: struct { op: BinOp, lhs: *const Expr, rhs: *const Expr },
    literal: i64,

    fn deinit(e: *const Expr, gpa: std.mem.Allocator) void {
        switch (e.*) {
            .binary => |b| {
                b.lhs.deinit(gpa);
                b.rhs.deinit(gpa);
            },
            .literal => {},
        }
        gpa.destroy(e);
    }
    fn interp(e: *const Expr) i64 {
        return switch (e.*) {
            .binary => |b| {
                const lhs = b.lhs.interp();
                const rhs = b.rhs.interp();
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
};

fn new(gpa: std.mem.Allocator, expr: Expr) *const Expr {
    const e = gpa.create(Expr) catch @panic("OOM");
    e.* = expr;
    return e;
}
fn lit(gpa: std.mem.Allocator, n: i64) *const Expr {
    return new(gpa, .{ .literal = n });
}
fn bin(gpa: std.mem.Allocator, op: BinOp, lhs: *const Expr, rhs: *const Expr) *const Expr {
    return new(gpa, .{ .binary = .{ .op = op, .lhs = lhs, .rhs = rhs } });
}

pub fn main() void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const gpa = debug_allocator.allocator();
    const e = bin(gpa, .div, bin(gpa, .mul, bin(gpa, .sub, lit(gpa, 7), lit(gpa, 10)), lit(gpa, 7)), lit(gpa, 2));
    defer e.deinit(gpa);
    std.debug.print("{d}\n", .{e.interp()});
    {
        const f = bin(gpa, .div, bin(gpa, .add, lit(gpa, 4), lit(gpa, 4)), bin(gpa, .sub, lit(gpa, 4), lit(gpa, 4)));
        defer f.deinit(gpa);
        std.debug.print("{d}\n", .{f.interp()});
    }
    std.debug.print("{d}\n", .{e.interp()});
}
