package arcane.internal;

#if js
typedef AudioDriver = arcane.internal.html5.WebAudioDriver;
typedef AudioBuffer = arcane.internal.html5.WebAudioDriver.AudioBuffer;
typedef AudioSource = arcane.internal.html5.WebAudioDriver.AudioSource;
#elseif (hl && kinc)
typedef AudioDriver = arcane.internal.kinc.KincAudioDriver;
typedef AudioBuffer = arcane.internal.kinc.KincAudioDriver.AudioBuffer;
typedef AudioSource = arcane.internal.kinc.KincAudioDriver.AudioSource;
#else
typedef AudioDriver = arcane.internal.empty.AudioDriver;
typedef AudioBuffer = arcane.internal.empty.AudioDriver.AudioBuffer;
typedef AudioSource = arcane.internal.empty.AudioDriver.AudioSource;
#end