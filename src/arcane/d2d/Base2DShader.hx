package arcane.d2d;

@:vertex("#version 450
in vec2 pos;
in vec2 uv;
in vec4 color;

uniform mat4 mvp;

out vec2 frag_uv;
out vec4 frag_color;
void main(){
    frag_uv = uv;
    frag_color = color;
    gl_Position = vec4(pos,0,1);
}")
@:fragment("#version 450

in vec2 frag_uv;
in vec4 frag_color;
out vec4 FragColor;

uniform sampler2D tex;

void main(){
    FragColor = texture(tex,frag_uv);
}")
class Base2DShader extends asl.Shader {}