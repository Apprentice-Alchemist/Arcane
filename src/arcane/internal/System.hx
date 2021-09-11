package arcane.internal;

// This is the type that should be overriden for backends in seperate libraries
// For backends in arcane itself, they should be added here.

#if js
typedef System = arcane.internal.html5.HTML5System;
#elseif (hl && kinc)
typedef System = arcane.internal.kinc.KincSystem;
#else
typedef System = arcane.internal.empty.EmptySystem;
#end
