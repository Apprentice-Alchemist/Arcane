package arcane.internal;

import haxe.macro.Expr;
import haxe.macro.Context;

class Macros {
    public static macro function initBackends(bm_expr:Expr,pb_expr:Expr){
        var cp = Context.getClassPath();
        var backends = new Map<String,haxe.macro.Expr>();
        return macro null;
        // return macro { ${bm_expr} = new Map<String,arcane.internal.Backend>(); ${pb_expr} = "hello";};
    }
}