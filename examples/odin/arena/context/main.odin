// For each start value, the Collatz trajectory down to 1 is built as a
// temporary list in an arena, and only two numbers are kept from it: how
// many steps it took, and the largest value on the way. The arena is reset
// between start values.
package main

import "core:fmt"
import "core:mem/virtual"

Summary :: struct { steps: int, peak: u64 }

// Allocates the trajectory with `context.allocator`, whatever that is.
summarize :: proc(start: u64) -> Summary {
	path := make([dynamic]u64)
	n := start
	append(&path, n)
	for n != 1 {
		n = n % 2 == 0 ? n / 2 : 3 * n + 1
		append(&path, n)
	}
	peak := path[0]
	for x in path[1:] {
		peak = max(peak, x)
	}
	return {len(path) - 1, peak}
}

main :: proc() {
	arena: virtual.Arena
	if err := virtual.arena_init_growing(&arena); err != nil {
		panic("arena")
	}
	defer virtual.arena_destroy(&arena)
	context.allocator = virtual.arena_allocator(&arena)
	for start in ([]u64{6, 7, 27, 97}) {
		defer free_all(context.allocator)
		summary := summarize(start)
		fmt.println(start, summary.steps, summary.peak)
	}
}
