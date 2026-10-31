// Comptime duck typing: the pool is `anytype` and its index type is whatever
// its `Ref` declaration says. There is no interface to check a pool against,
// so a mismatch only shows up when some call instantiates the function.
const std = @import("std");

const BinOp = enum(i64) { add = 1, sub, mul, div }; // 0 means a literal.

fn Expr(comptime R: type) type {
    return union(enum) {
        binary: struct { op: BinOp, lhs: R, rhs: R },
        literal: i64,
    };
}

fn RefOf(comptime P: type) type {
    return std.meta.Child(P).Ref;
}

fn interp(p: anytype, expr: RefOf(@TypeOf(p))) i64 {
    return switch (p.get(expr)) {
        .binary => |b| {
            const lhs = interp(p, b.lhs);
            const rhs = interp(p, b.rhs);
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
fn lit(p: anytype, n: i64) RefOf(@TypeOf(p)) {
    return p.add(.{ .literal = n });
}
fn bin(p: anytype, op: BinOp, lhs: RefOf(@TypeOf(p)), rhs: RefOf(@TypeOf(p))) RefOf(@TypeOf(p)) {
    return p.add(.{ .binary = .{ .op = op, .lhs = lhs, .rhs = rhs } });
}

fn node(comptime R: type, op: i64, lhs: i64, rhs: i64) Expr(R) {
    if (op == 0) return .{ .literal = lhs };
    return .{ .binary = .{ .op = @enumFromInt(op), .lhs = @enumFromInt(lhs), .rhs = @enumFromInt(rhs) } };
}

// Representation 1: a node is an index into parallel lists.
const Idx = enum(u32) { _ };

const Columns = struct {
    const Ref = Idx;

    ops: std.ArrayList(i64) = .empty,
    lhs: std.ArrayList(i64) = .empty,
    rhs: std.ArrayList(i64) = .empty,
    gpa: std.mem.Allocator,

    fn add(c: *Columns, expr: Expr(Idx)) Idx {
        const row: [3]i64 = switch (expr) {
            .binary => |b| .{ @intFromEnum(b.op), @intFromEnum(b.lhs), @intFromEnum(b.rhs) },
            .literal => |num| .{ 0, num, 0 },
        };
        for ([_]*std.ArrayList(i64){ &c.ops, &c.lhs, &c.rhs }, row) |column, x|
            column.append(c.gpa, x) catch @panic("OOM");
        return @enumFromInt(c.ops.items.len - 1);
    }
    fn get(c: *const Columns, expr: Idx) Expr(Idx) {
        const i = @intFromEnum(expr);
        return node(Idx, c.ops.items[i], c.lhs.items[i], c.rhs.items[i]);
    }
};

// Representation 2: a node is an index into one list of triples.
const Slot = enum(u32) { _ };

const Triples = struct {
    const Ref = Slot;

    triples: std.ArrayList(i64) = .empty,
    gpa: std.mem.Allocator,

    fn add(t: *Triples, expr: Expr(Slot)) Slot {
        const triple: [3]i64 = switch (expr) {
            .binary => |b| .{ @intFromEnum(b.op), @intFromEnum(b.lhs), @intFromEnum(b.rhs) },
            .literal => |num| .{ 0, num, 0 },
        };
        t.triples.appendSlice(t.gpa, &triple) catch @panic("OOM");
        return @enumFromInt(t.triples.items.len / 3 - 1);
    }
    fn get(t: *const Triples, expr: Slot) Expr(Slot) {
        const i = 3 * @as(usize, @intFromEnum(expr));
        return node(Slot, t.triples.items[i], t.triples.items[i + 1], t.triples.items[i + 2]);
    }
};

pub fn main() void {
    const gpa = std.heap.page_allocator;
    var a: Columns = .{ .gpa = gpa };
    const e = bin(&a, .div, bin(&a, .mul, bin(&a, .sub, lit(&a, 7), lit(&a, 10)), lit(&a, 7)), lit(&a, 2));
    std.debug.print("{d}\n", .{interp(&a, e)});
    {
        var b: Triples = .{ .gpa = gpa };
        std.debug.print("{d}\n", .{interp(&b, bin(&b, .div, bin(&b, .add, lit(&b, 4), lit(&b, 4)), bin(&b, .sub, lit(&b, 4), lit(&b, 4))))});
    }
    std.debug.print("{d}\n", .{interp(&a, e)});
}
