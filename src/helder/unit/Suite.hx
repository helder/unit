package helder.unit;

import helder.unit.util.Duration.formatDuration;
import helder.unit.util.Ansi.ansi;
import haxe.Exception;
import haxe.ds.Either;
import helder.unit.Assert.Assertion;
using StringTools;

abstract Setup<T>(Null<Either<() -> T, (done: (result: T) -> Void) -> Void>>) {
  public function new(either) this = either;
  @:from public static function fromSync<T>(sync: () -> T) 
    return new Setup<T>(Left(sync));
  @:from public static function fromVoidAsync<T>(async: (done: () -> Void) -> Void)
    return new Setup<T>(Right(done -> async(() -> @:nullSafety(Off) done(null))));
  @:from public static function fromAsync<T>(async: (done: (result: T) -> Void) -> Void) 
    return new Setup<T>(Right(async));
  public function get(done: (result: T) -> Void)
    return switch this {
      case null: @:nullSafety(Off) done(null);
      case Left(sync): done(sync());
      case Right(async): async(done);
    }
}

abstract Before<P1, T>(Null<Either<(p1: P1) -> T, (p1: P1, done: (result: T) -> Void) -> Void>>) {
  public function new(either) this = either;
  @:from public static function fromVoidSync<P1, T>(sync: () -> T)
    return new Before<P1, T>(Left(p1 -> sync()));
  @:from public static function fromSync<P1, T>(sync: (p1: P1) -> T) 
    return new Before<P1, T>(Left(sync));
  @:from public static function fromVoidAsync<P1, T>(async: (p1: P1, done: () -> Void) -> Void)
    return new Before<P1, T>(Right((p1, done) -> async(p1, () -> @:nullSafety(Off) done(null))));
  @:from public static function fromAsync<P1, T>(async: (p1: P1, done: (result: T) -> Void) -> Void) 
    return new Before<P1, T>(Right(async));
  public function get(p1: P1, done: (result: T) -> Void)
    return switch this {
      case null: @:nullSafety(Off) done(null);
      case Left(sync): done(sync(p1));
      case Right(async): async(p1, done);
    }
}

abstract After<P1>(Null<Either<(p1: P1) -> Void, (p1: P1, done: () -> Void) -> Void>>) {
  public function new(either) this = either;
  @:from public static function fromVoidSync<P1>(sync: () -> Void) 
    return new After<P1>(Left(p1 -> sync()));
  @:from public static function fromSkipAsync<P1>(async: (done: () -> Void) -> Void) 
    return new After<P1>(Right((p1, done) -> async(done)));
  @:from public static function fromSync<P1>(sync: (p1: P1) -> Void) 
    return new After<P1>(Left(sync));
  @:from public static function fromAsync<P1>(async: (p1: P1, done: () -> Void) -> Void) 
    return new After<P1>(Right(async));
  public function get(p1: P1, done: () -> Void)
    return switch this {
      case null: done();
      case Left(sync): sync(p1); done();
      case Right(async): async(p1, done);
    }
}

typedef SuiteOptions<S, T> = {
  ?name: String,
  ?setup: Setup<S>,
  ?before: Before<S, T>,
  ?after: After<T>,
  ?teardown: After<S>
}

typedef Test<T> = {
  name: String,
  run: After<T>
}

class TestMethodTools {
  public static function only<S, T>(t: TestMethod<S, T>, name: String, run: After<T>) {
    t(name, run, {only: true});
  }
  public static function skip<S, T>(t: TestMethod<S, T>, name: String, run: After<T>) {
    t(name, run, {skip: true});
  }
}

typedef TestOptions = {?only: Bool, ?skip: Bool}

@:using(helder.unit.Suite.TestMethodTools)
typedef TestMethod<S, T> = (name: String, run: After<T>, ?options: TestOptions) -> Suite<S, T>;

typedef RunResult = {
  total: Int, 
  passed: Int, 
  skips: Int, 
  duration: Float
}

class Suite<S, T> {
  final options: SuiteOptions<S, T>;
  final only: Array<Test<T>> = [];
  final tests: Array<Test<T>> = [];
  var skips = 0; 

  public function new(?options: SuiteOptions<S, T>) {
    this.options = switch options{
      case null: {}
      case v: cast Reflect.copy(v);
    }
  }
  public function setName(name: String) {
    options.name = name;
    return this;
  }
  public function test(name: String, run: After<T>, ?options: TestOptions) {
    if (options != null && options.skip) {
      skips++;
    }
    final collection = options != null && options.only ? this.only : this.tests;
    collection.push({name: name, run: run});
    return this;
  }
  function formatFail(name: String, e: Exception) {
    final stack = try e.stack.toString() catch(_) '';
    final quote = ansi.dim('"');
    var message = '\n  ' + ansi.bold(ansi.bgRed(' FAIL '));
    message += ' $quote${ansi.red(ansi.bold(name))}$quote';
    message += '\n    ' + try e.message catch(_) Std.string(e);
    if (e is Assertion) {
      final assertion: Assertion = cast e;
      message += ansi.dim(ansi.italic(' (${assertion.op})'));
      final pos = assertion.pos;
      message += ansi.cyan('\n    > ${pos.fileName}:${pos.lineNumber}');
      message += ('\n\n     Expected: ${assertion.expected}');
      message += ('\n       Actual: ${assertion.actual}');
    } else {
      final gutter = '\n      ';
      message += ansi.gray(
        gutter +
        stack.split('\n').map(line -> {
          var max = 120;
          if (line.length < max) return line;
          var res = [];
          while (line.length > 0) {
            res.push(line.substr(0, max));
            line = line.substr(max);
          }
          return res.join(gutter + '  ');
        }).join(gutter)
      );
    }
    return message + '\n';
  }
  public function run(done: (res: RunResult) -> Void) {
    var passed = 0;
    final start = Sys.time();
    final errors: Array<String> = [];
    function finish(ctx) {
      options.teardown.get(ctx, () -> {
        final total = only.length + tests.length + skips;
        final success = total == skips + passed;
        final msg = ' (${passed} / ${total})\n\n';
        final duration = (Sys.time() - start) * 1000;
        write(success ? ansi.green(msg) : ansi.red(msg));
        for (error in errors)
          Sys.println(error);
        done({
          total: total,
          passed: passed,
          skips: skips,
          duration: duration
        });
      });
    }
    if (options.name != null)
      write(ansi.bold(ansi.underline(ansi.white(options.name))) + '\n');
    options.setup.get(ctx -> {
      final collection = only.length > 0 ? only : tests; 
      final iter = collection.iterator();
      function next() {
        if (!iter.hasNext()) return finish(ctx);
        options.before.get(ctx, ctx -> {
          final test = iter.next();
          capture(done -> {
            test.run.get(ctx, done);
          }, (?exception: Exception) -> {
            final fail = Assertion.last != null ? Assertion.last : exception;
            if (fail != null) {
              write(ansi.red('✘ '));
              errors.push(formatFail(test.name, fail));
            } else {
              passed++;
              write(ansi.gray('• '));
            }
            options.after.get(ctx, () -> {
              next();
            });
          });
        });
      }
      next();
    });
  }
  static function write(output: String) {
    Sys.print(output);
  }
  function capture(run: (done: () -> Void) -> Void, cb: (?e: Exception) -> Void) {
    function done() cb();
    function main() try run(done) catch (e) cb(e);
    Assertion.reset();
    #if nodejs
    final process = js.Node.process;
    function capture(e) {
      cb(e);
      process.off('uncaughtException', capture);
    }
    process.on('uncaughtException', capture);
    run(() -> {
      process.off('uncaughtException', capture);
      done();
    });
    #elseif eval
    eval.luv.UVError.setOnUnhandledException((e) -> {
      final exitMsg = 'EvalExceptions.Sys_exit(';
      if (e.message.startsWith(exitMsg)) {
        final code = Std.parseInt(e.message.substr(
          exitMsg.length, 
          exitMsg.length - exitMsg.indexOf(')')  
        ));
        if (code != null) Sys.exit(code);
      }
      cb(e);
    });
    main();
    #else
    main();
    #end
  }
  public static function runMultiple(
    suites: Array<Suite<Dynamic, Dynamic>>,
    ?done: (res: RunResult) -> Void
  ) {
    var endRes: RunResult = {total: 0, passed: 0, skips: 0, duration: 0}
    function finish(res: RunResult) {
      final success = res.total == res.skips + res.passed;
      write('  Total:     ' + res.total);
      write((success ? ansi.green : ansi.red)('\n  Passed:    ' +  res.passed));
      write('\n  Skipped:   ' + (res.skips > 0 ? ansi.yellow('${res.skips}') : '0'));
      write('\n  Duration:  ' + formatDuration(res.duration) + '\n');
      if (done != null) @:nullSafety(Off) done(res);
    }
    function next() {
      if (suites.length == 0) return finish(endRes);
      final suite = suites.shift();
      @:nullSafety(Off) suite.run(res -> {
        endRes = {
          total: endRes.total + res.total,
          passed: endRes.passed + res.passed,
          skips: endRes.skips + res.skips,
          duration: endRes.duration + res.duration,
        }
        next();
      });
    }
    next();
  }
}