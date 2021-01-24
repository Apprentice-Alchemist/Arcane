package arcane;

/**
 * A Single on C++, Hashlink, Java or C#, a regular Float on other platforms.
 */
#if (cpp || hl || java || cs)
typedef FastFloat = Single;
#else
typedef FastFloat = Float;
#end