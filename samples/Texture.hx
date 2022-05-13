import arcane.arrays.Int32Array;
import arcane.arrays.Float32Array;
import arcane.system.IGraphicsDriver;
import arcane.Lib;
import arcane.Image;

@:vert({
	@:in var pos:Vec3;
	@:in var uv:Vec2;
	@:out var f_uv:Vec2;
	@:builtin(position) var position:Vec4;
	function main() {
		f_uv = uv;
		position = vec4(pos, 1.0);
	}
})
@:frag({
	@:in var f_uv:Vec2;
	@:out var color:Vec4;
	@:uniform var tex:Texture2D;
	function main() {
		color = tex.get(f_uv);
	}
})
private class MyShader extends asl.Shader {}

function main() {
	arcane.Lib.init(() -> {
		arcane.Assets.loadBytesAsync("res/parrot.png", bytes -> {
			arcane.Utils.assert(bytes != null);
			final d:IGraphicsDriver = cast Lib.gdriver;
			final parrot = Image.fromPngBytes(bytes).expect().toTexture(d);
			final vertex_attributes:Array<VertexAttribute> = [
				{
					name: "pos",
					kind: Float3
				},
				{
					name: "uv",
					kind: Float2
				}
			];
			final vbuf = d.createVertexBuffer({
				size: 6,
				instanceDataStepRate: 0,
				attributes: vertex_attributes
			});
			vbuf.upload(0, Float32Array.fromArray([
				-1, -1, 0,0,1,
				 1, -1, 0,1,1,
				-1,  1, 0,0,0,
                1, -1, 0,1,1,
				 1,  1, 0, 1,0,
                 -1,  1, 0,0,0
			]));
			final ibuf = d.createIndexBuffer({
				size: 6
			});
			ibuf.upload(0, Int32Array.fromArray([
				0, 1, 2,
				3,4,5
			]));

			final shader = new MyShader().make(d);
			arcane.Utils.assert(shader.vertex != null);
			arcane.Utils.assert(shader.fragment != null);
            
            final bind_group_layout = d.createBindGroupLayout({
                entries: [{
                    visibility: Fragment,
                    binding: 0,
                    kind: Texture(Filtering)
                }]
            });
			final pipeline = d.createRenderPipeline({
				inputLayout: [{instanced: false, attributes: vertex_attributes}],
				vertexShader: shader.vertex,
				fragmentShader: shader.fragment,
				culling: None,
                layout: [bind_group_layout]
			});

            final sampler = d.createSampler({});
            final bind_group = d.createBindGroup({layout: bind_group_layout, entries: [{binding: 0, resource: Texture(parrot, sampler)}]});

			Lib.update.add((dt) -> {
				final encoder = d.createCommandEncoder();
				final pass = encoder.beginRenderPass({colorAttachments: [{texture: d.getCurrentTexture(), load: Clear, store: Store}]});
				pass.setPipeline(pipeline);
				pass.setVertexBuffer(vbuf);
				pass.setIndexBuffer(ibuf);
                pass.setBindGroup(0, bind_group);
				pass.draw(0, 6);
				pass.end();
				final b = encoder.finish();
				d.submit([b]);
				d.present();
			});
		}, error -> throw error
		);
	});
}
