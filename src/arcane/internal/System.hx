package arcane.internal;

#if js
typedef System = arcane.internal.html5.HTML5System;
#elseif (hl && kinc)
typedef System = arcane.internal.kinc.KincSystem;
#else
typedef System = arcane.internal.empty.System;
#end
