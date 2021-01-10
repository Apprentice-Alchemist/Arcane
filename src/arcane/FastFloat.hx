package arcane;

/**
 * A Single on C++, Hashlink, Java or C#, a regular Float on other platforms.
 * 
 * Only use this in graphics code, not game logic!
 * (Unless you want inconsistent math)
 */
#if (cpp || hl || java || cs)
typedef FastFloat = Single;
#else
typedef FastFloat = Float;
#end