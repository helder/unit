package tests;

import helder.unit.Assert.assert;
import haxe.Timer;
import helder.Unit.suite;

final TestAsync = suite(test -> {
  test('async finish', done -> {
    Timer.delay(done, 10);
  });

  test('async assert', done -> {
    assert.ok(true);
    Timer.delay(() -> {
      assert.ok(true);
      done();
    }, 10);
  });
});