package tests;

import haxe.Exception;

final TestAssert = suite(test -> {
  test('ok', () -> {
    assert.ok(true);
    assert.not.ok(false);
  });
  
  test('is', () -> {
    assert.is(1, 1);
    assert.not.is(1, 2);
  });

  test('equal', () -> {
    assert.equal({a: 1}, {a: 1});
    assert.not.equal({a: 1}, {a: 2});
  });

  test('instance', () -> {
    assert.instance('test', String);
    assert.not.instance(1, String);
  });

  test('throws', () -> {
    function check(e: Exception) {
      return e.message == 'thrown';
    }
    assert.throws(() -> throw new Exception('thrown'), check);
    assert.not.throws(() -> {}, check);
  });
});