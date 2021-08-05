package asl;

// import haxe.macro.Expr;
import asl.Ast.Expr as AslExpr;
#if macro
import haxe.macro.Context;
#end

class Parser {
	public static function error(pos:haxe.macro.Expr.Position, msg:String) {
		#if macro
		return Context.error(msg, pos);
		#else
		return throw new haxe.macro.Expr.Error(msg, pos);
		#end
	}

	static function parse(e:haxe.macro.Expr) {
		var inputs = [];
		var outputs = [];
		var uniforms = [];
		var functions = [];
		switch e {
			case macro $b{exprs} :
				for (expr in exprs) {
					switch expr {
						case macro @:in $e:
							switch e.expr {
								case EVars(vars):
									for (v in vars) {
										if (v.type == null)
											error(e.pos, "Input variables should have an explicit type.");
										inputs.push(v);
									}
								case _:
							}
						case macro @:out $e:
							switch e.expr {
								case EVars(vars):
									for (v in vars) {
										if (v.type == null)
											error(e.pos, "Output variables should have an explicit type.");
										outputs.push(v);
									}
								case _:
							}
						case macro @:uniform $e:
							switch e.expr {
								case EVars(vars):
									for (v in vars) {
										if (v.type == null)
											error(e.pos, "Uniform variables should have an explicit type.");
										uniforms.push(v);
									}
								case _:
							}
						case e.expr => EFunction(FNamed(name, false), f): functions.push({
								name: name,
								args: f.args,
								expr: f.expr.sure(),
								ret: f.ret
							});
						case _:
					}
				}
			case _:
				error(e.pos, "Expected a block.");
		}
	}

	static function conv(e:Null<haxe.macro.Expr>):Null<AslExpr> {
        if(e == null) return null;
		return {
			pos: e.pos,
			expr: switch e.expr {
				case EConst(c): EConst(c);
				case EArray(e1, e2): EArray(conv(e1), conv(e2));
				case EBinop(op, e1, e2): EBinop(op, conv(e1), conv(e2));
				case EField(e, field): EField(conv(e), field);
				case EParenthesis(e): EParenthesis(conv(e));
				case EObjectDecl(fields): EObjectDecl(fields.map(f -> {name: f.field,expr:conv(f.expr)}));
				case EArrayDecl(values): EArrayDecl(values.map(conv));
				case ECall(e, params): ECall(conv(e),params.map(conv));
				case EUnop(op, postFix, e): EUnop(op,postFix,conv(e));
				case EVars(vars): EVars(vars.map(struct -> {
                    name: struct.name,
                    expr: conv(struct.expr),
                    isFinal: struct.isFinal,
                    type: struct.type
                }));
				case EBlock(exprs): EBlock(exprs.map(conv));
				case EFor(it, expr): EFor(conv(it),conv(expr));
				case EIf(econd, eif, eelse): EIf(conv(econd),conv(eif),conv(eelse));
				case EWhile(econd, e, normalWhile): EWhile(conv(econd),conv(e),normalWhile);
				// case ESwitch(e, cases, edef): cast null;
				case EReturn(e): EReturn(conv(e));
				case EBreak: EBreak;
				case EContinue: EContinue;
				case EDisplay(e, displayKind): cast null;
				case ETernary(econd, eif, eelse): ETernary(conv(econd),conv(eif),conv(eelse));
				case EMeta(s, e): cast null;
				case _: error(e.pos, "Unsupported error.");
			}
		}
	}
}
