package asl;

import haxe.macro.Context;
import haxe.macro.Expr;
import asl.Ast;

abstract Pos(asl.Ast.Position) from asl.Ast.Position to asl.Ast.Position {
	#if macro
	@:from static function fromP(p:haxe.macro.Expr.Position) {
		return cast Context.getPosInfos(p);
	}

	@:to function toP() {
		return Context.makePosition(this);
	}
	#end
}

@:nullSafety(Off)
class Typer {
	static var builtins:Map<String, Array<{}>> = [];
	@:noCompletion static var __id:Int = 0;

	static function allocID():Int {
		return __id++;
	}

	var vars:Map<String, TVar> = [];
	var ret_type:Type = TVoid;

	public function new() {}

	public static function makeModule(id:String, e:Expr, stage:ShaderStage):ShaderModule {
		final typer = new Typer();
		return switch e.expr {
			case EBlock(exprs): typer.typeModule(id, exprs, stage);
			case _: throw "expected block declaration";
		}
	}

	function typeModule(id:String, exprs:Array<Expr>, stage:ShaderStage):ShaderModule {
		var uniforms:Array<TVar> = [];
		var outputs = [];
		var inputs = [];
		var functions:Array<{
			var name:String;
			var args:Array<TVar>;
			var ret:Type;
			var expr:TypedExpr;
		}> = [];
		var entryPoint = "main";
		for (e in exprs) {
			switch e {
				case macro @:in var $name:$t:
					var tvar:TVar = {
						id: allocID(),
						name: name,
						t: toType(t, e.pos),
						kind: Input
					};
					inputs.push(tvar);
					vars.set(name, tvar);
				case macro @:uniform var $name:$t:
					var tvar:TVar = {
						id: allocID(),
						name: name,
						t: toType(t, e.pos),
						kind: Uniform
					};
					uniforms.push(tvar);
					vars.set(name, tvar);

				case macro @:out var $name:$t:
					var tvar:TVar = {
						id: allocID(),
						name: name,
						t: toType(t, e.pos),
						kind: Output
					};
					outputs.push(tvar);
					vars.set(name, tvar);
				case macro @:builtin(${_b = _.expr => EConst(CString(s)) | EConst(CIdent(s))}) var $name:$t:
					var b:Builtin = try Builtin.fromString(s) catch (e) error(Std.string(e), _b.pos);
					var kind = b.kind(stage);
					var tvar:TVar = {
						id: allocID(),
						name: name,
						t: toType(t, e.pos),
						kind: kind,
						builtin: b
					};
						(switch kind {
							case Input: inputs;
							case Output: outputs;
							case _: throw "assert";
						}).push(tvar);
					vars.set(name, tvar);
				case _.expr => EFunction(_ => FNamed(name, _), f):
					functions.push(scope(() -> {
						{
							name: name,
							args: [
								for (arg in f.args) {
									final v:TVar = {
										id: allocID(),
										name: arg.name,
										t: toType(arg.type, e.pos),
										kind: Local
									};
									vars.set(v.name, v);
									v;
								}
							],
							ret: ret_type = (f.ret == null ? TMonomorph({value: null}) : toType(f.ret, e.pos)),
							expr: typeExpr(f.expr)
						}
					}));

				case _:
			}
		}
		for (f in functions)
			switch f.ret {
				case TMonomorph(r):
					if (r.value == null)
						r.value = TVoid;
				case _:
			}
		return {
			id: id,
			uniforms: uniforms,
			stage: stage,
			outputs: outputs,
			inputs: inputs,
			functions: functions,
			entryPoint: entryPoint
		}
	}

	function follow(t:Type) {
		return switch t {
			case TMonomorph(r): r.value == null ? follow(t) : r.value;
			case _: t;
		}
	}

	function tryUnify(a:Type, b:Type):Bool {
		if (a == b)
			return true;
		return switch [a, b] {
			case [TVec(a, s1), TVec(b, s2)] if (a == b && s1 == s2): true;
			case [TMat(a, s1), TMat(b, s2)] if (a == b && s1 == s2): true;
			case [TArray(t1, size1), TArray(t2, size2)] if (t1 == t2 && size1 == size2): true;
			case [TMonomorph(r), t] if (r.value != null):
				r.value = t;
				true;
			case [t, TMonomorph(r)] if (r.value != null):
				r.value = t;
				true;
			case [_, _]: false;
		}
	}

	function unify(a:Type, b:Type, pos:Pos) {
		if (!tryUnify(a, b))
			error(a + " should be " + b, pos);
	}

	public static function error(message:String, pos:Pos):Dynamic {
		#if macro
		return haxe.macro.Context.fatalError(message, pos);
		#else
		return throw message;
		#end
	}

	function toFloat(e:TypedExpr) {
		if (e.t != TInt)
			throw "assert";
		switch (e.expr) {
			case TConst(TInt(v)):
				e.expr = TConst(TFloat(Std.string(v)));
				e.t = TFloat;
			default:
				// e.expr = TCall({e: TGlobal(ToFloat), t: TFun([]), p: e.p}, [{e: e.e, t: e.t, p: e.p}]);
				// e.t = TFloat;
		}
	}

	function unifyExpr(e:TypedExpr, t:Type) {
		if (!tryUnify(e.t, t)) {
			if (follow(e.t) == TInt && follow(t) == TFloat) {
				toFloat(e);
				return;
			}
			error(e.t + " should be " + t, e.pos);
		}
	}

	function typeBinop(op:Binop, e1:TypedExpr, e2:TypedExpr, pos:Pos) {
		return switch (op) {
			case OpAssign, OpAssignOp(_): throw "assert";
			case OpMult, OpAdd, OpSub, OpDiv, OpMod:
				switch ([op, e1.t, e2.t]) {
					case [OpMult, TMat(TFloat, 4), TVec(TFloat, 4)]:
						TVec(TFloat, 4);
					// case [OpMult, TVec(TFloat,3), TMat3x4]:
					// 	vec3;
					case [OpMult, TVec(TFloat, 3), TMat(TFloat, 3)]:
						TVec(TFloat, 3);
					case [OpMult, TVec(TFloat, 2), TMat(TFloat, 2)]:
						TVec(TFloat, 2);
					case [_, TInt, TInt]: TInt;
					case [_, TFloat, TFloat]: TFloat;
					case [_, TInt, TFloat]:
						toFloat(e1);
						TFloat;
					case [_, TFloat, TInt]:
						toFloat(e2);
						TFloat;
					case [_, TVec(TFloat, size1), TVec(TFloat, size2)] if (size1 == size2): TVec(TFloat, size1);
					case [_, TFloat, TVec(TFloat, _)]: e2.t;
					case [_, TVec(TFloat, _), TFloat]: e1.t;
					case [_, TInt, TVec(TFloat, _)]:
						toFloat(e1);
						e2.t;
					case [_, TVec(TFloat, _), TInt]:
						toFloat(e2);
						e1.t;
					case [OpMult, TMat(TFloat, size1), TMat(TFloat, size2)] if (size1 == size2): TMat(TFloat, size1);
					default:
						var opName = switch (op) {
							case OpMult: "multiply";
							case OpAdd: "add";
							case OpSub: "subtract";
							case OpDiv: "divide";
							default: throw "assert";
						}
						error("Cannot " + opName + " " + e1.t + " and " + e2.t, pos);
				}
			case OpLt, OpGt, OpLte, OpGte, OpEq, OpNotEq:
				switch (e1.t) {
					case TFloat, TInt if (e2.t != TVoid):
						unifyExpr(e2, e1.t);
						TBool;
					case TBool if ((op == OpEq || op == OpNotEq) && e2.t != TVoid):
						unifyExpr(e2, e1.t);
						TBool;
					case TVec(_) if (e2.t != TVoid):
						unifyExpr(e2, e1.t);
						e1.t;
					default:
						switch ([e1.expr, e2.expr]) {
							// case [TVar(v), TConst(CNull)], [TConst(CNull), TVar(v)]:
							// 	if (!v.hasQualifier(Nullable))
							// 		error("Variable is not declared as nullable", e1.p);
							// 	TBool;
							default:
								error("Cannot compare " + e1.t + " and " + e2.t, pos);
						}
				}
			case OpBoolAnd, OpBoolOr:
				unifyExpr(e1, TBool);
				unifyExpr(e2, TBool);
				TBool;
			case OpInterval:
				unifyExpr(e1, TInt);
				unifyExpr(e2, TInt);
				TArray(TInt, 0);
			case OpShl, OpShr, OpUShr, OpOr, OpAnd, OpXor:
				unifyExpr(e1, TInt);
				unifyExpr(e2, TInt);
				TInt;
			default:
				error("Unsupported operator " + op, pos);
		}
	}

	function checkWrite(e:TypedExpr) {
		switch (e.expr) {
			case TLocal(v):
				switch (v.kind) {
					case Local, Output:
						return;
					default:
				}
			case TField(e, _):
				checkWrite(e);
				return;
			default:
		}
		error("This expression cannot be assigned", e.pos);
	}

	function typeExpr(e:Expr):TypedExpr {
		var type:Null<Type> = null;
		final expr:TypedExprDef = switch e.expr {
			case EConst(CIdent("PI")):
				type = TFloat;
				TConst(TFloat(Std.string(Math.PI)));
			case EConst(CIdent("true")):
				type = TBool;
				TConst(TBool(true));
			case EConst(CIdent("false")):
				type = TBool;
				TConst(TBool(false));
			case EConst(CIdent(name)) if (name != "vec4"):
				var v = vars.get(name);
				if (v != null) {
					type = v.t;
					TLocal(v);
				} else {
					trace(name);
					error("TODO", e.pos);
				}
			case EConst(c):
				switch c {
					case CInt(i):
						type = TInt;
						TConst(TInt(Std.parseInt(i)));
					case CFloat(f):
						type = TFloat;
						TConst(TFloat(f));
					case _: error("Invalid expression", e.pos);
				}
			case EArray(typeExpr(_) => e1, typeExpr(_) => e2):
				var t = switch e1.t {
					case TMat(t, size): TVec(t, size);
					case TVec(t, _), TArray(t, _): t;
					case _: error("Cannot do array access on " + e1.t, e1.pos);
				}
				if (e2.t != TInt)
					error("Expected an integer", e1.pos);
				type = t;
				TypedExprDef.TArray(e1, e2);
			case EBinop(op, typeExpr(_) => e1, typeExpr(_) => e2):
				switch (op) {
					case OpAssign:
						checkWrite(e1);
						unify(e2.t, e1.t, e2.pos);
						type = e1.t;
					case OpAssignOp(op):
						checkWrite(e1);
						unify(typeBinop(op, e1, e2, e.pos), e1.t, e2.pos);
						type = e1.t;
					default:
						type = typeBinop(op, e1, e2, e.pos);
				}
				TBinop(op, e1, e2);
			case EField(typeExpr(_) => e, name):
				var fa:Null<FieldAccess> = null;
				switch follow(e.t) {
					case TMonomorph(r): error("This expression does not have a concrete type.", e.pos);
					case TVec(t, size):
						final str = "xrsygtzbpwaq";
						final comps = [X, Y, Z, W];
						var cat = -1;
						final out = [];
						for (i in 0...name.length) {
							var idx = str.indexOf(name.charAt(i));
							if (idx < 0)
								return null;
							var icat = idx % 3;
							if (cat < 0)
								cat = icat
							else if (icat != cat)
								break; // down't allow .ryz
							var cid = Std.int(idx / 3);
							if (cid >= size)
								error(typeToString(e.t) + " does not have component " + name.charAt(i), e.pos);
							out.push(comps[cid]);
						}
						type = switch out.length {
							case 1: t;
							case var l: TVec(t, l);
						}
						fa = TSwiz(out);
					case TMat(t, size):
					case TStruct(fields):
						for (field in fields)
							if (field.name == name) {
								type = field.type;
								fa = FStruct(name);
								break;
							}
					case _:
				}
				if (fa == null) {
					error('${typeToString(e.t)} has no field $name', e.pos);
				}
				TField(e, fa);

			case EParenthesis(typeExpr(_) => e):
				type = e.t;
				TParenthesis(e);
			case ECall(e = _.expr => EConst(CIdent(vec = "vec4" | "vec3" | "vec2")), _.map(typeExpr) => params):
				final vec_size = switch vec {
					case "vec4": 4;
					case "vec3": 3;
					case "vec2": 2;
					default: error("Should be vec4 | vec3 | vec2.", e.pos);
				}
				final vec_type = switch params[0].t {
					case TBool: TBool;
					case TInt: TInt;
					case TFloat: TFloat;
					case TVec(t, size): t;
					case var t: error("Expected Float, Int or Bool, not " + typeToString(t), params[0].pos);
				};
				var param_size:Int = 0;
				for (param in params) {
					param_size += switch param.t {
						case TBool, TInt, TFloat:
							unify(param.t, vec_type, param.pos);
							1;
						case TVec(t, size):
							unify(t, vec_type, param.pos);
							size;
						case var t: error("Expected Float, Int or Bool, not " + typeToString(t), param.pos);
					}
				}
				if (vec_size != param_size) {
					error('Got $param_size components in arguments, expected $vec_size', e.pos);
				}
				type = TVec(vec_type, vec_size);
				TCallBuiltin(switch vec_size {
					case 4: BuiltinVec4(vec_type);
					case 3: BuiltinVec3(vec_type);
					case 2: BuiltinVec2(vec_type);
					default: throw "assert";
				}, [for (p in params) p]);
			// case EObjectDecl(fields):
			// case EArrayDecl(values):
			case ECall(_.expr => EConst(CIdent("mix")), [typeExpr(_) => col1, typeExpr(_) => col2, typeExpr(_) => f]):
				unifyExpr(col1, TVec(TFloat, 4));
				unifyExpr(col2, TVec(TFloat, 4));
				unifyExpr(f, TFloat);
				type = TVec(TFloat, 4);
				TCallBuiltin(BuiltinMix, [col1, col2, f]);
			case ECall(_.expr => EField(typeExpr(_) => e, "get"), [typeExpr(_) => uv]):
				unifyExpr(e, TSampler2D);
				unifyExpr(uv, TVec(TFloat, 2));
				type = TVec(TFloat, 4);
				TCallBuiltin(BuiltinSampleTexture, [e, uv]);
			case EUnop(op, postFix, typeExpr(_) => e):
				type = e.t;
				TUnop(op, postFix, e);
			case EVars(_vars):
				if (_vars.length != 1)
					error("Multi variable declarations not yet supported", e.pos);
				var v = _vars[0];
				var expr = v.expr == null ? null : typeExpr(v.expr);
				var t = v.type == null ? expr.t : toType(v.type, e.pos);
				unifyExpr(expr, t);
				var v:TVar = {
					id: allocID(),
					name: v.name,
					t: t,
					kind: Local
				};
				vars.set(v.name, v);
				TVar(v, expr);
			case EBlock(exprs):
				type = TVoid;
				scope(() -> TBlock([for (e in exprs) typeExpr(e)]));
			case EFor(it, expr):
				error("TODO", e.pos);
			case EIf(typeExpr(_) => econd, typeExpr(_) => eif, typeExpr(_) => eelse):
				unifyExpr(econd, TBool);
				TIf(econd, eif, eelse);
			case EWhile(typeExpr(_) => econd, typeExpr(_) => e, normalWhile):
				unifyExpr(econd, TBool);
				type = e.t;
				TWhile(econd, e, normalWhile);
			case EReturn(e):
				final ret_expr = if (e == null) null else typeExpr(e);
				if (ret_expr == null) {
					type = TVoid;
				} else {
					unifyExpr(ret_expr, ret_type);
					type = follow(ret_type);
				}
				TReturn(ret_expr);
			case EBreak:
				type = TVoid;
				TBreak;
			case EContinue:
				type = TVoid;
				TContinue;
			// case EDisplay(e, displayKind):
			// case ETernary(typeExpr(_) => econd, typeExpr(_) => eif, typeExpr(_) => eelse):
			// 	unifyExpr(econd,TBool);
			// 	type = unify(eif.t,eelse.t,e.pos);
			// 	TTernary
			// case EMeta(s, e):
			default: error("Invalid expression", e.pos);
		}
		return {
			expr: expr,
			t: type,
			pos: (e.pos : Pos)
		}
	}

	function scope<T>(f:() -> T) {
		final old = vars.copy();
		final ret = f();
		vars = old;
		return ret;
	}

	function toType(c:ComplexType, pos:Pos) {
		return switch c {
            // @formatter:off
            case macro:Bool: TBool;
            case macro:Int: TInt;
            case macro:Float: TFloat;

            // VecX<T:Bool | Int | Float = Float> 
            case macro:Vec2: TVec(TFloat,2);
            case macro:Vec3: TVec(TFloat,3);
            case macro:Vec4: TVec(TFloat,4);
            case macro:Vec2<$t>: TVec(toType(t,pos),2);
            case macro:Vec3<$t>: TVec(toType(t,pos),3);
            case macro:Vec4<$t>: TVec(toType(t,pos),4);

            // MatX<T:Bool | Int | Float = Float> 
            case macro:Mat2: TMat(TFloat,2);
            case macro:Mat3: TMat(TFloat,3);
            case macro:Mat4: TMat(TFloat,4);
            case macro:Mat2<$t>: TMat(toType(t,pos),2);
            case macro:Mat3<$t>: TMat(toType(t,pos),3);
            case macro:Mat4<$t>: TMat(toType(t,pos),4);

			case macro:Texture2D: TSampler2D;

			case TPath({pack: [], name: "Array", params: [TPType(toType(_,pos) => t),TPExpr(_.expr => EConst(CInt(Std.parseInt(_) => size)))], sub: null}):
				if(t.match(TArray(_,_))) error("Multidimensional arrays not supported",pos);
				TArray(t,size);
            // @formatter:on
			case TAnonymous(fields): TStruct([
					for (field in fields)
						{
							name: field.name,
							type: toType(switch field.kind {
								case FVar(t, e):
									if (e != null)
										error("Did not expect an expression here", e.pos);
									t;
								case _: error("Not supported", field.pos);
							}, pos)
						}]);
			default: error("Unsupported type", pos);
		}
	}

	static function typeToString(t:Type) {
		return switch t {
			case TVoid: "Void";
			case TBool: "Bool";
			case TInt: "Int";
			case TFloat: "Float";
			case TVec(t, size): 'Vec<${typeToString(t)}, $size>';
			case TMat(t, size): 'Vec<${typeToString(t)}, $size>';
			case TArray(t, size): 'Array<${typeToString(t)}, $size>';
			case TStruct(fields): '{\n${fields.map(f -> 'var ${f.name}:${typeToString(f.type)};\n')}}';
			case TSampler2D: 'Sampler2D';
			case TSampler2DArray: 'Sampler2DArray';
			case TSamplerCube: 'SamplerCube';
			case TMonomorph(r): switch r.value {
					case null: 'Unknown';
					case var t: typeToString(t);
				}
		}
	}

	public static function sizeof(t:Type) {
		return switch t {
			case TMonomorph(r): sizeof(cast r.value);
			case TVoid: 0;
			case TBool: 1;
			case TInt: 4;
			case TFloat: 4;
			case TVec(t, size): sizeof(t) * size;
			case TMat(t, size): sizeof(t) * size * size;
			case TArray(t, size): sizeof(t) * size;
			case TStruct(fields):
				var s = 0;
				for (f in fields)
					s += sizeof(f.type);
				s;
			case TSampler2D: throw "unsized type";
			case TSampler2DArray: throw "unsized type";
			case TSamplerCube: throw "unsized type";
		}
	}
}
