package arcane.internal;

#if js
typedef GraphicsDriver = arcane.internal.html5.WebGLDriver;
typedef ConstantLocation = arcane.internal.html5.WebGLDriver.ConstantLocation;
typedef TextureUnit = arcane.internal.html5.WebGLDriver.TextureUnit;
typedef Texture = arcane.internal.html5.WebGLDriver.Texture;
typedef Pipeline = arcane.internal.html5.WebGLDriver.Pipeline;
typedef Shader = arcane.internal.html5.WebGLDriver.Shader;
typedef VertexBuffer = arcane.internal.html5.WebGLDriver.VertexBuffer;
typedef IndexBuffer = arcane.internal.html5.WebGLDriver.IndexBuffer;
#elseif (hl && kinc)
typedef GraphicsDriver = arcane.internal.kinc.KincDriver;
typedef ConstantLocation = arcane.internal.kinc.KincDriver.ConstantLocation;
typedef TextureUnit = arcane.internal.kinc.KincDriver.TextureUnit;
typedef Texture = arcane.internal.kinc.KincDriver.Texture;
typedef Pipeline = arcane.internal.kinc.KincDriver.Pipeline;
typedef Shader = arcane.internal.kinc.KincDriver.Shader;
typedef VertexBuffer = arcane.internal.kinc.KincDriver.VertexBuffer;
typedef IndexBuffer = arcane.internal.kinc.KincDriver.IndexBuffer;
#else
typedef GraphicsDriver = arcane.internal.empty.GraphicsDriver;
typedef ConstantLocation = arcane.internal.empty.GraphicsDriver.ConstantLocation;
typedef TextureUnit = arcane.internal.empty.GraphicsDriver.TextureUnit;
typedef Texture = arcane.internal.empty.GraphicsDriver.Texture;
typedef Pipeline = arcane.internal.empty.GraphicsDriver.Pipeline;
typedef Shader = arcane.internal.empty.GraphicsDriver.Shader;
typedef VertexBuffer = arcane.internal.empty.GraphicsDriver.VertexBuffer;
typedef IndexBuffer = arcane.internal.empty.GraphicsDriver.IndexBuffer;
#end
