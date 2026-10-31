// Each piece of context is a trait, and a logger is a value passed to every
// function that logs. Rebinding the maximum level for a scope means wrapping
// the logger in a new type, which must also pass through everything else.

trait MaybeLog {
    fn error(&self, message: u32);
    fn warn(&self, message: u32);
    fn info(&self, message: u32);
    fn debug(&self, message: u32);
    fn trace(&self, message: u32);
}

trait ForceLog {
    fn force_error(&self, message: u32);
    fn force_warn(&self, message: u32);
    fn force_info(&self, message: u32);
    fn force_debug(&self, message: u32);
    fn force_trace(&self, message: u32);
}

trait Log: MaybeLog + ForceLog {}

struct MaxLevelInfo<'a, T>(&'a T);

impl<T: ForceLog> ForceLog for MaxLevelInfo<'_, T> {
    fn force_error(&self, message: u32) {
        self.0.force_error(message)
    }

    fn force_warn(&self, message: u32) {
        self.0.force_warn(message)
    }

    fn force_info(&self, message: u32) {
        self.0.force_info(message)
    }

    fn force_debug(&self, message: u32) {
        self.0.force_debug(message)
    }

    fn force_trace(&self, message: u32) {
        self.0.force_trace(message)
    }
}

impl<T: ForceLog> MaybeLog for MaxLevelInfo<'_, T> {
    fn error(&self, message: u32) {
        self.0.force_error(message)
    }

    fn warn(&self, message: u32) {
        self.0.force_warn(message)
    }

    fn info(&self, message: u32) {
        self.0.force_info(message)
    }

    fn debug(&self, _: u32) {}

    fn trace(&self, _: u32) {}
}

impl<T: ForceLog> Log for MaxLevelInfo<'_, T> {}

struct MaxLevelDebug<'a, T>(&'a T);

impl<T: ForceLog> ForceLog for MaxLevelDebug<'_, T> {
    fn force_error(&self, message: u32) {
        self.0.force_error(message)
    }

    fn force_warn(&self, message: u32) {
        self.0.force_warn(message)
    }

    fn force_info(&self, message: u32) {
        self.0.force_info(message)
    }

    fn force_debug(&self, message: u32) {
        self.0.force_debug(message)
    }

    fn force_trace(&self, message: u32) {
        self.0.force_trace(message)
    }
}

impl<T: ForceLog> MaybeLog for MaxLevelDebug<'_, T> {
    fn error(&self, message: u32) {
        self.0.force_error(message)
    }

    fn warn(&self, message: u32) {
        self.0.force_warn(message)
    }

    fn info(&self, message: u32) {
        self.0.force_info(message)
    }

    fn debug(&self, message: u32) {
        self.0.force_debug(message)
    }

    fn trace(&self, _: u32) {}
}

impl<T: ForceLog> Log for MaxLevelDebug<'_, T> {}

struct Stdout;

impl ForceLog for Stdout {
    fn force_error(&self, message: u32) {
        println!("{message}")
    }

    fn force_warn(&self, message: u32) {
        println!("{message}")
    }

    fn force_info(&self, message: u32) {
        println!("{message}")
    }

    fn force_debug(&self, message: u32) {
        println!("{message}")
    }

    fn force_trace(&self, message: u32) {
        println!("{message}")
    }
}

fn foo(logger: &impl Log) {
    logger.debug(3);
}

fn bar(logger: &impl Log) {
    logger.info(1);
    logger.debug(2);
    {
        let logger = &MaxLevelDebug(logger);
        foo(logger);
    }
    logger.debug(4);
}

fn baz(logger: &impl ForceLog) {
    let logger = &MaxLevelInfo(logger);
    bar(logger);
}

fn main() {
    baz(&Stdout);
}
