// For each start value, the Collatz trajectory down to 1 is built as a
// temporary list in an arena, and only two numbers are kept from it: how
// many steps it took, and the largest value on the way. The arena is reset
// between start values.
const std = @import("std");

const Summary = struct { steps: usize, peak: u64 };

fn summarize(allocator: std.mem.Allocator, start: u64) !Summary {
    var path: std.ArrayList(u64) = .empty;
    var n = start;
    try path.append(allocator, n);
    while (n != 1) {
        n = if (n % 2 == 0) n / 2 else 3 * n + 1;
        try path.append(allocator, n);
    }
    var peak = path.items[0];
    for (path.items[1..]) |x| peak = @max(peak, x);
    return .{ .steps = path.items.len - 1, .peak = peak };
}

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    for ([_]u64{ 6, 7, 27, 97 }) |start| {
        defer _ = arena.reset(.retain_capacity);
        const summary = try summarize(arena.allocator(), start);
        std.debug.print("{d} {d} {d}\n", .{ start, summary.steps, summary.peak });
    }
}
