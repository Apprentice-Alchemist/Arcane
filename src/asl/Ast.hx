package asl;

typedef ComplexType = haxe.macro.Expr.ComplexType;

enum Type {
	TBool;
	TInt;
	TFloat;

	TVec2(t:Type);
	TVec3(t:Type);
	TVec4(t:Type);
	TMat2(t:Type);
	TMat3(t:Type);
	TMat4(t:Type);
}

// Geometry, tesselation and co aren't supported on webgpu/webgl, compute isn't supported on webgl.
enum ShaderStage {
	Vertex;
	Fragment;
	Compute;
}

@:structInit class ShaderModule {
	final stage:ShaderStage;
	final inputs:Array<{
		var name:String;
		var type:Type;
	}>;
	final outputs:Array<{
		var name:String;
		var type:Type;
	}>;
	final uniforms:Array<{
		var name:String;
		var type:String;
	}>;
	final functions:Array<{
		var name:String;
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
	var pos:haxe.macro.Expr.Position;

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

	/**
		The constant `this`.
	**/
	TThis;

	/**
		The constant `super`.
	**/
	TSuper;
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

	/**
		Whether or not the variable has been captured by a closure.
	**/
	public var capture(default, never):Bool;

	/**
		Special information which is internally used to keep track of closure.
		information
	**/
	// public var extra(default, never):Null<{params:Array<TypeParameter>, expr:Null<TypedExpr>}>;

	/**
		The metadata of the variable.
	**/
	public var meta(default, never):Null<haxe.macro.Type.MetaAccess>;
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
	// /**
	// 	Access of field `cf` on a class instance `c` with type parameters
	// 	`params`.
	// **/
	// FInstance(c:Ref<ClassType>, params:Array<Type>, cf:Ref<ClassField>);
	// /**
	// 	Static access of a field `cf` on a class `c`.
	// **/
	// FStatic(c:Ref<ClassType>, cf:Ref<ClassField>);
	// /**
	// 	Access of field `cf` on an anonymous structure.
	// **/
	// FAnon(cf:Ref<ClassField>);
	// /**
	// 	Dynamic field access of a field named `s`.
	// **/
	// FDynamic(s:String);
	// /**
	// 	Closure field access of field `cf` on a class instance `c` with type
	// 	parameters `params`.
	// **/
	// FClosure(c:Null<{c:Ref<ClassType>, params:Array<Type>}>, cf:Ref<ClassField>);
	// /**
	// 	Field access to an enum constructor `ef` of enum `e`.
	// **/
	// FEnum(e:Ref<EnumType>, ef:EnumField);
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
	TSwitch(e:TypedExpr, cases:Array<{values:Array<TypedExpr>, expr:TypedExpr}>, edef:Null<TypedExpr>);

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

	/**
		An unknown identifier.
	**/
	TIdent(s:String);
}
