// Each piece of context is an interface, and a logger is a value passed to
// every function that logs, whose type is a type parameter the compiler
// infers at each call and specializes for. Rebinding the maximum level for a
// scope means wrapping the logger in a new type, which must also pass
// through everything else; a constructor can't infer a struct's type
// argument, so each wrapping names it.

interface IMaybeLog
{
    void error(uint message);
    void warn(uint message);
    void info(uint message);
    void debug(uint message);
    void trace(uint message);
}

interface IForceLog
{
    void forceError(uint message);
    void forceWarn(uint message);
    void forceInfo(uint message);
    void forceDebug(uint message);
    void forceTrace(uint message);
}

interface ILog : IMaybeLog, IForceLog {}

struct MaxLevelInfo<T : IForceLog> : ILog
{
    T log;

    void forceError(uint message) { log.forceError(message); }
    void forceWarn(uint message) { log.forceWarn(message); }
    void forceInfo(uint message) { log.forceInfo(message); }
    void forceDebug(uint message) { log.forceDebug(message); }
    void forceTrace(uint message) { log.forceTrace(message); }

    void error(uint message) { log.forceError(message); }
    void warn(uint message) { log.forceWarn(message); }
    void info(uint message) { log.forceInfo(message); }
    void debug(uint message) {}
    void trace(uint message) {}
}

struct MaxLevelDebug<T : IForceLog> : ILog
{
    T log;

    void forceError(uint message) { log.forceError(message); }
    void forceWarn(uint message) { log.forceWarn(message); }
    void forceInfo(uint message) { log.forceInfo(message); }
    void forceDebug(uint message) { log.forceDebug(message); }
    void forceTrace(uint message) { log.forceTrace(message); }

    void error(uint message) { log.forceError(message); }
    void warn(uint message) { log.forceWarn(message); }
    void info(uint message) { log.forceInfo(message); }
    void debug(uint message) { log.forceDebug(message); }
    void trace(uint message) {}
}

struct Stdout : IForceLog
{
    void forceError(uint message) { printf("%u\n", message); }
    void forceWarn(uint message) { printf("%u\n", message); }
    void forceInfo(uint message) { printf("%u\n", message); }
    void forceDebug(uint message) { printf("%u\n", message); }
    void forceTrace(uint message) { printf("%u\n", message); }
}

void foo<L : ILog>(L log)
{
    log.debug(3);
}

void bar<L : ILog>(L log)
{
    log.info(1);
    log.debug(2);
    {
        let log = MaxLevelDebug<L>(log);
        foo(log);
    }
    log.debug(4);
}

void baz<F : IForceLog>(F log)
{
    let log = MaxLevelInfo<F>(log);
    bar(log);
}

export __extern_cpp int main()
{
    baz(Stdout());
    return 0;
}
