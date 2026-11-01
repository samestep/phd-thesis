// For each start value, the Collatz trajectory down to 1 is built as a
// temporary list in an arena, and only two numbers are kept from it: how
// many steps it took, and the largest value on the way. The arena is reset
// between start values.
use bumpalo::{collections::Vec, Bump};

struct Summary {
    steps: usize,
    peak: u64,
}

fn summarize(bump: &Bump, start: u64) -> Summary {
    let mut path = Vec::new_in(bump);
    let mut n = start;
    path.push(n);
    while n != 1 {
        n = if n % 2 == 0 { n / 2 } else { 3 * n + 1 };
        path.push(n);
    }
    Summary {
        steps: path.len() - 1,
        peak: *path.iter().max().unwrap(),
    }
}

fn main() {
    let mut bump = Bump::new();
    for start in [6, 7, 27, 97] {
        let summary = summarize(&bump, start);
        println!("{start} {} {}", summary.steps, summary.peak);
        bump.reset();
    }
}
