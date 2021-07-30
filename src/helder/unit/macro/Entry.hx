package helder.unit.macro;

import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.TypeTools;
import haxe.macro.Expr;
import haxe.io.Path;
import sys.FileSystem;

// from tink_macro
private function drill(parts:Array<String>, pos:Position) {
  var target = {expr: EConst(CIdent(parts.shift())), pos: pos}
  for (part in parts)
    target = {expr: EField(target, part), pos: pos}
  return target;
}

macro function entry() {
  final paths = Context.getClassPath();
  final pack = Context.definedValue('helder.unit.package');
  final modules = [];
  function read(location: String, pack: String) {
    for (file in FileSystem.readDirectory(location)) {
      final path = haxe.io.Path.join([location, file]);
      final type = '$pack.$file';
      if (FileSystem.isDirectory(path)) 
        read(path, type);
      else if (StringTools.endsWith(type, '.hx') && file != 'import.hx')
        modules.push(type.substr(0, -3));
    }
  }
  for (path in paths)  {
    final location = Path.join([path, pack]);
    if (FileSystem.exists(location))
      read(location, pack);
  }
  final code: Array<Expr> = [];
  for (module in modules) {
    Compiler.include(module);
    final types = Context.getModule(module);
    final name = module.split('.').pop();
    for (type in types) {
      switch type {
        case TInst(_.get() => {
          kind: KModuleFields(_), 
          statics: _.get() => fields}, _):
          for (field in fields) {
            if (TypeTools.unify(
              Context.getType('helder.unit.Suite'),
              field.type
            )) {
              code.push(
                {expr: 
                  ECall(drill(
                    module.split('.').concat([field.name, 'setName']),
                    field.pos
                  ),
                    [macro $v{module + '.' + field.name}]
                  ),
                  pos:field.pos
                }
                
              );
            }
          }
        default:
      }
    }
  }
  return macro helder.unit.Suite.runMultiple($a{code}, null);
}