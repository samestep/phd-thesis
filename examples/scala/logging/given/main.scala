// Each piece of context is a given, resolved by type at every call site.
// Rebinding the maximum level for a scope is a nested given that shadows the
// outer one; but every function lists the givens it uses, and they are
// passed at run time, so a disabled level is an empty method call. Once the
// code is hot, the JIT inlines it away only while each call site has seen few
// enough logger classes.

trait MaybeLog:
  def error(message: Int): Unit
  def warn(message: Int): Unit
  def info(message: Int): Unit
  def debug(message: Int): Unit
  def trace(message: Int): Unit

trait ForceLog:
  def forceError(message: Int): Unit
  def forceWarn(message: Int): Unit
  def forceInfo(message: Int): Unit
  def forceDebug(message: Int): Unit
  def forceTrace(message: Int): Unit

class MaxLevelInfo(using log: ForceLog) extends MaybeLog:
  def error(message: Int) = log.forceError(message)
  def warn(message: Int) = log.forceWarn(message)
  def info(message: Int) = log.forceInfo(message)
  def debug(message: Int) = ()
  def trace(message: Int) = ()

class MaxLevelDebug(using log: ForceLog) extends MaybeLog:
  def error(message: Int) = log.forceError(message)
  def warn(message: Int) = log.forceWarn(message)
  def info(message: Int) = log.forceInfo(message)
  def debug(message: Int) = log.forceDebug(message)
  def trace(message: Int) = ()

object Stdout extends ForceLog:
  def forceError(message: Int) = println(message)
  def forceWarn(message: Int) = println(message)
  def forceInfo(message: Int) = println(message)
  def forceDebug(message: Int) = println(message)
  def forceTrace(message: Int) = println(message)

def foo(using log: MaybeLog) =
  log.debug(3)

def bar(using log: MaybeLog, force: ForceLog) =
  log.info(1)
  log.debug(2)
  locally {
    given MaybeLog = MaxLevelDebug()
    foo
  }
  log.debug(4)

def baz(using ForceLog) =
  given MaybeLog = MaxLevelInfo()
  bar

@main def run() =
  given ForceLog = Stdout
  baz
