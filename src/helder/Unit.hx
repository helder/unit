package helder;

import helder.unit.Suite;

function suite<S, T>(?options: SuiteOptions<S, T>, defineTests: (test: TestMethod<S, T>) -> Void) {
  final suite = new Suite<S, T>(options);
  defineTests(suite.test);
  return suite;
}

/*inline function suite<S, T>(options: SuiteOptions<S, T>) {
  return (defineTests: (test: TestMethod<S, T>) -> Void) -> {
    return suite(options, defineTests);
  }
}*/

final assert = helder.unit.Assert.assert;

function main()
  helder.unit.macro.Entry.entry((res) -> {
    #if !watch
    final status = if (res.total == res.passed + res.skips) 0 else 1;
    Sys.exit(status);
    #end
  });