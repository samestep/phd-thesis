// The pool is passed explicitly, like a Zig allocator.
const std = @import("std");

const Node = union(enum) { lit: i64, add: [2]u32, mul: [2]u32 };

const Pool = struct {
    nodes: std.ArrayList(Node) = .empty,
    gpa: std.mem.Allocator,

    fn push(p: *Pool, node: Node) u32 {
        p.nodes.append(p.gpa, node) catch @panic("OOM");
        return @intCast(p.nodes.items.len - 1);
    }
    fn lit(p: *Pool, n: i64) u32 {
        return p.push(.{ .lit = n });
    }
    fn add(p: *Pool, l: u32, r: u32) u32 {
        return p.push(.{ .add = .{ l, r } });
    }
    fn mul(p: *Pool, l: u32, r: u32) u32 {
        return p.push(.{ .mul = .{ l, r } });
    }
    fn eval(p: *const Pool, e: u32) i64 {
        return switch (p.nodes.items[e]) {
            .lit => |n| n,
            .add => |c| p.eval(c[0]) + p.eval(c[1]),
            .mul => |c| p.eval(c[0]) * p.eval(c[1]),
        };
    }
};

pub fn main() void {
    const gpa = std.heap.page_allocator;
    var a: Pool = .{ .gpa = gpa };
    const e = a.mul(a.add(a.lit(1), a.lit(2)), a.add(a.lit(3), a.lit(4)));
    std.debug.print("{d}\n", .{a.eval(e)});
    {
        var b: Pool = .{ .gpa = gpa };
        std.debug.print("{d}\n", .{b.eval(b.add(b.lit(4), b.lit(4)))});
    }
    std.debug.print("{d}\n", .{a.eval(e)});
}
