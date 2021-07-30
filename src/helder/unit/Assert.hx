package helder.unit;

import haxe.PosInfos;
import haxe.display.Position;
import deepequal.DeepEqual;

import haxe.Exception;

class Assertion extends Exception {
  public final actual: Any;
  public final expected: Any;
  public final op: String;
  public final pos: PosInfos;
  public static var last: Null<Assertion>;
  public function new(message: String, actual: Any, expected: Any, op: String, pos: PosInfos) {
    super(message);
    this.actual = actual;
    this.expected = expected;
    this.op = op;
    this.pos = pos;
    last = this;
  }
  public static function reset()
    last = null;
}

private function doAssert<T>(check: Bool, actual: T, expected: T, op: String, message: String, pos: PosInfos) {
  if (check) return;
  throw new Assertion(message, actual, expected, op, pos);
}

function ok(check: Bool, ?pos: PosInfos) {
  doAssert(check, false, true, 'ok', 'Expected value to be truthy', pos);
}

function is<T>(a: T, b: T, ?pos: PosInfos) {
  doAssert(a == b, a, b, 'is', 'Expected values to be equal', pos);
}

function equal<T>(a: T, b: T, ?pos: PosInfos) {
  switch DeepEqual.compare(a, b) {
    case Success(_):
    case Failure(error):
      doAssert(false, a, b, 'equal', error.message, pos);
  }
}

function unreachable(?pos: PosInfos) {
	doAssert(false, true, false, 'unreachable', 'Expected not to be reached!', pos);
}

function instance(value: Any, type: Class<Dynamic>, ?pos: PosInfos) {
	doAssert(Std.isOfType(value, type), value, type, 'type', 'Expected value to be an instance of ${type}', pos);
}

function throws(run: () -> Void, expected: (e: Exception) -> Bool, ?pos: PosInfos) {
  try {
    run();
		doAssert(false, false, true, 'throws', 'Expected function to throw', pos);
  } catch (e) {
		if (e is Assertion) throw e;
		doAssert(expected(e), false, true, 'throws', 'Expected function to throw matching exception', pos);
  }
}

function notOk(check: Bool, ?pos: PosInfos) {
  doAssert(!check, false, true, 'not', 'Expected value to be falsey', pos);
}

function notIs<T>(a: T, b: T, ?pos: PosInfos) {
  doAssert(a != b, a, b, 'is', 'Expected values not be equal', pos);
}

function notEqual<T>(a: T, b: T, ?pos: PosInfos) {
  switch DeepEqual.compare(a, b) {
    case Success(_):
      doAssert(false, a, b, 'equal', 'Expected values not to be deeply equal', pos);
    case Failure(error):
  }
}

function notInstance(value: Any, type: Class<Dynamic>, ?pos: PosInfos) {
	doAssert(!Std.isOfType(value, type), value, type, 'type', 'Expected value not to be an instance of ${type}', pos);
}

function notThrows(run: () -> Void, expected: (e: Exception) -> Bool, ?pos: PosInfos) {
  try {
    run();
  } catch (e) {
		doAssert(!expected(e), false, true, 'throws', 'Expected function not to throw matching exception', pos);
  }
}

final assert = {
  ok: ok,
  is: is,
  equal: equal,
  unreachable: unreachable,
  instance: instance,
  throws: throws,
  not: {
    ok: notOk,
    is: notIs,
    equal: notEqual,
    instance: notInstance,
    throws: notThrows
  }
}