package helder.unit;

import haxe.PosInfos;
import deepequal.DeepEqual;
import haxe.Exception;
import helder.unit.Assert.Assertion.create;

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

  static public function create<T>(check: Bool, actual: T, expected: T, op: String, message: String, pos: PosInfos) {
    if (check) return;
    throw new Assertion(message, actual, expected, op, pos);
  }  
}

class AssertNotTools {
  public function new() {}
    
  public function ok(check: Bool, ?pos: PosInfos) {
    create(!check, false, true, 'not', 'Expected value to be falsey', pos);
  }

  public function is<T>(a: T, b: T, ?pos: PosInfos) {
    create(a != b, a, b, 'is', 'Expected values not be equal', pos);
  }

  public function equal<T>(a: T, b: T, ?pos: PosInfos) {
    switch DeepEqual.compare(a, b) {
      case Success(_):
        create(false, a, b, 'equal', 'Expected values not to be deeply equal', pos);
      case Failure(error):
    }
  }

  public function instance(value: Any, type: Class<Dynamic>, ?pos: PosInfos) {
    create(!Std.isOfType(value, type), value, type, 'type', 'Expected value not to be an instance of ${type}', pos);
  }

  public function throws(run: () -> Void, expected: (e: Exception) -> Bool, ?pos: PosInfos) {
    try {
      run();
    } catch (e) {
      create(!expected(e), false, true, 'throws', 'Expected function not to throw matching exception', pos);
    }
  }
}

class AssertTools {
  public function new() {}

  public final not = new AssertNotTools();

  public function ok(check: Bool, ?pos: PosInfos) {
    create(check, false, true, 'ok', 'Expected value to be truthy', pos);
  }
  
  public function is<T>(a: T, b: T, ?pos: PosInfos) {
    create(a == b, a, b, 'is', 'Expected values to be equal', pos);
  }
  
  public function equal<T>(a: T, b: T, ?pos: PosInfos) {
    switch DeepEqual.compare(a, b) {
      case Success(_):
      case Failure(error):
        create(false, a, b, 'equal', error.message, pos);
    }
  }
  
  public function unreachable(?pos: PosInfos) {
    create(false, true, false, 'unreachable', 'Expected not to be reached!', pos);
  }
  
  public function instance(value: Any, type: Class<Dynamic>, ?pos: PosInfos) {
    create(Std.isOfType(value, type), value, type, 'type', 'Expected value to be an instance of ${type}', pos);
  }
  
  public function throws(run: () -> Void, expected: (e: Exception) -> Bool, ?pos: PosInfos) {
    try {
      run();
      create(false, false, true, 'throws', 'Expected function to throw', pos);
    } catch (e) {
      if (e is Assertion) throw e;
      create(expected(e), false, true, 'throws', 'Expected function to throw matching exception', pos);
    }
  }
}

final assert = new AssertTools();