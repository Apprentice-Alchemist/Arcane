package asl;

/**
	Represents a position in a file.
**/
typedef Position = {
	/**
		Reference to the filename.
	**/
	var file:String;

	/**
		Position of the first character.
	**/
	var min:Int;

	/**
		Position of the last character.
	**/
	var max:Int;
}

typedef Ref<T> = {
	var value:T;
}

enum Type {
	TMonomorph(r:Ref<Null<Type>>);

	TVoid;
	TBool;

	/**
	 * 32 integer.
	 */
	TInt;

	/**
	 * 32 bit floating point number
	 */
	TFloat;

	/**
	 * Allowed sizes : 2, 3, 4.
	 * Allowed types : bool, int and float.
	 */
	TVec(t:Type, size:Int);

	TMat(t:Type, size:Int);
	TArray(t:Type, ?size:Int);
	TStruct(fields:Array<{name:String, type:Type}>);
	TSampler2D;
	TSampler2DArray;
	TSamplerCube;
}

// Geometry, tesselation and co aren't supported on webgpu/webgl/metal, compute isn't supported on webgl.
enum ShaderStage {
	Vertex;
	Fragment;
	Compute;
}

enum abstract Builtin(String) from String {
	var position;
	var instanceIndex;

	public static function fromString(s:String):Builtin {
		return cast switch (cast s : Builtin) {
			case position, instanceIndex: s;
			case _:
				throw "unknown builtin";
		}
	}

	public function kind(stage:ShaderStage):TVarKind {
		return switch (cast this : Builtin) {
			case position: Output;
			case instanceIndex: Input;
		}
	}
}

enum BuiltinFunction {
	BuiltinVec4(t:Type);
	BuiltinVec3(t:Type);
	BuiltinVec2(t:Type);
}

typedef ShaderModule = {
	final id:String;
	final stage:ShaderStage;
	final inputs:Array<TVar>;
	final outputs:Array<TVar>;
	final uniforms:Array<TVar>;
	final functions:Array<{
		var name:String;
		var args:Array<TVar>;
		var ret:Type;
		var expr:TypedExpr;
	}>;
	final entryPoint:String;
}

/**
	Represents a typed AST node.
 */
typedef TypedExpr = {
	/**
		The expression kind.
	**/
	var expr:TypedExprDef;

	/**
		The position of the expression.
	**/
	var pos:Position;

	/**
		The type of the expression.
	**/
	var t:Type;
}

/**
	Represents typed constant.
 */
enum TConstant {
	/**
		An `Int` literal.
	**/
	TInt(i:Int);

	/**
		A `Float` literal, represented as String to avoid precision loss.
	**/
	TFloat(s:String);

	/**
		A `String` literal.
	**/
	TString(s:String);

	/**
		A `Bool` literal.
	**/
	TBool(b:Bool);

	/**
		The constant `null`.
	**/
	TNull;
}

enum TVarKind {
	Input;
	Output;
	Local;
	Uniform;
}

/**
	Represents a variable in the typed AST.
 */
typedef TVar = {
	/**
		The unique ID of the variable.
	**/
	public var id(default, never):Int;

	/**
		The name of the variable.
	**/
	public var name(default, never):String;

	/**
		The type of the variable.
	**/
	public var t(default, never):Type;

	public var kind:TVarKind;
	@:optional public var builtin:Builtin;
}

/**
	Represents a function in the typed AST.
 */
typedef TFunc = {
	/**
		A list of function arguments identified by an argument variable `v` and
		an optional initialization `value`.
	**/
	var args:Array<{v:TVar, value:Null<TypedExpr>}>;

	/**
		The return type of the function.
	**/
	var t:Type;

	/**
		The expression of the function body.
	**/
	var expr:TypedExpr;
}

/**
	Represents the kind of field access in the typed AST.
 */
enum FieldAccess {
	FMat(x:Int, ?y:Int);
	FStruct(name:String);
	TSwiz(components:Array<Component>);
}

enum TypedExprDef {
	/**
		A constant.
	**/
	TConst(c:TConstant);

	/**
		Reference to a local variable `v`.
	**/
	TLocal(v:TVar);

	/**
		Array access `e1[e2]`.
	**/
	TArray(e1:TypedExpr, e2:TypedExpr);

	/**
		Binary operator `e1 op e2`.
	**/
	TBinop(op:haxe.macro.Expr.Binop, e1:TypedExpr, e2:TypedExpr);

	/**
		Field access on `e` according to `fa`.
	**/
	TField(e:TypedExpr, fa:FieldAccess);

	// /**
	// 	Reference to a module type `m`.
	// **/
	// TTypeExpr(m:ModuleType);

	/**
		Parentheses `(e)`.
	**/
	TParenthesis(e:TypedExpr);

	/**
		An object declaration.
	**/
	TObjectDecl(fields:Array<{name:String, expr:TypedExpr}>);

	/**
		An array declaration `[el]`.
	**/
	TArrayDecl(el:Array<TypedExpr>);

	/**
		A call `e(el)`.
	**/
	TCall(e:TypedExpr, el:Array<TypedExpr>);

	/**
		A call to a builtin function `e(el)`.
	**/
	TCallBuiltin(b:BuiltinFunction, el:Array<TypedExpr>);

	/**
		An unary operator `op` on `e`:

		* e++ (op = OpIncrement, postFix = true)
		* e-- (op = OpDecrement, postFix = true)
		* ++e (op = OpIncrement, postFix = false)
		* --e (op = OpDecrement, postFix = false)
		* -e (op = OpNeg, postFix = false)
		* !e (op = OpNot, postFix = false)
		* ~e (op = OpNegBits, postFix = false)
	**/
	TUnop(op:haxe.macro.Expr.Unop, postFix:Bool, e:TypedExpr);

	/**
		A variable declaration `var v` or `var v = expr`.
	**/
	TVar(v:TVar, expr:Null<TypedExpr>);

	/**
		A block declaration `{el}`.
	**/
	TBlock(el:Array<TypedExpr>);

	/**
		A `for` expression.
	**/
	TFor(v:TVar, e1:TypedExpr, e2:TypedExpr);

	/**
		An `if(econd) eif` or `if(econd) eif else eelse` expression.
	**/
	TIf(econd:TypedExpr, eif:TypedExpr, eelse:Null<TypedExpr>);

	/**
		Represents a `while` expression.
		When `normalWhile` is `true` it is `while (...)`.
		When `normalWhile` is `false` it is `do {...} while (...)`.
	**/
	TWhile(econd:TypedExpr, e:TypedExpr, normalWhile:Bool);

	/**
		Represents a `switch` expression with related cases and an optional
		`default` case if edef != null.
	**/
	// TSwitch(e:TypedExpr, cases:Array<{values:Array<TypedExpr>, expr:TypedExpr}>, edef:Null<TypedExpr>);

	/**
		A `return` or `return e` expression.
	**/
	TReturn(e:Null<TypedExpr>);

	/**
		A `break` expression.
	**/
	TBreak;

	/**
		A `continue` expression.
	**/
	TContinue;

	/**
		A `@m e1` expression.
	**/
	TMeta(m:haxe.macro.Expr.MetadataEntry, e1:TypedExpr);
}

enum Component {
	X;
	Y;
	Z;
	W;
}
