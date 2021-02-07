package arcane;

/**
 * - C++, Hashlink, Java, C# : single-precision IEEE 32bit float.
 * - Other :  double-precision IEEE 64bit float.
 * 
 * Should only be used in graphics code.
 */
#if (cpp || hl || java || cs)
typedef FastFloat = Single;
#else
typedef FastFloat = Float;
#end
