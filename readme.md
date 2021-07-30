# helder.unit

Simple, (mostly) macro-free test runner

## Usage

```
lix +lib helder.unit
```

Create test suites:

```haxe
import helder.Unit.suite;
import helder.Unit.assert;

final MyTest = suite(test -> {
  test('basic boolean checks', () -> {
    assert.ok(true);
    assert.not.ok(false);
  });
});
```

Create your own entry point to run the test suites:

```haxe
function main()
  helder.unit.Suite.runMultiple([MyTest]);
```

Or, let a macro find all your suites based on a package:

```
haxe -main helder.Unit -D helder.unit.package=tests
```

This will recursively find and run every test suite under `tests`.

## Assertions

```haxe
assert
  // Boolean check
  .ok(check: Bool);
  // Strict equal
  .is<T>(a: T, b: T);
  // Deep equal
  .equal<T>(a: T, b: T);
  // Fail if reached
  .unreachable();
  // Check if value is instance of type
  .instance(value: Any, type: Class<Dynamic>);
  // Check if exception was thrown
  .throws(run: () -> Void, expected: (e: Exception) -> Bool);

  .not
    // Boolean check for false
    .ok(check: Bool);
    // Not strictly equal
    .is<T>(a: T, b: T);
    // Not deeply equal
    .equal<T>(a: T, b: T);
    // Check if value is not instance of type
    .instance(value: Any, type: Class<Dynamic>);
    // Check if exception was not thrown
    .throws(run: () -> Void, expected: (e: Exception) -> Bool);
```

## API

```haxe
import helder.Unit.suite;
import helder.Unit.assert;

final Suite = suite({
  // Run once before tests, you can return some context
  setup: () -> {db: [1, 2, 3]},

  // Every lifecycle method can be used async
  // setup: done -> Timer.delay(() -> done(someContext), 1000)

  // Run before each test, receives setup context and can return its own
  before: setup -> {values: setup.db},

  // Run after each test, recieves context
  after: before -> trace(before.values),

  // Run once after all tests
  teardown: setup -> trace('tests are done')
}, test -> {
  
  test('check context', ctx -> {
    assert.equal(ctx.values, [1, 2, 3]);
  });

  test('async', done -> {
    // Complete test in 1 second
    haxe.Timer.delay(done, 1000);
  });

  test('async with context', (ctx, done) -> {
    haxe.Timer.delay(() -> {
      assert.equal(ctx.values, [1, 2, 3]);
      done();
    }, 1000);
  });

  test.only('only run this test', ...);

  test.skip('skip this test', ...);

});
```

