import arcane.util.Math.Matrix4;
import arcane.arrays.Int32Array;
import arcane.arrays.Float32Array;
import arcane.gpu.IVertexBuffer;
import arcane.gpu.IIndexBuffer;
import arcane.gpu.IBindGroup;
import arcane.gpu.IBindGroupLayout;
import arcane.gpu.ICommandBuffer;
import arcane.gpu.ICommandEncoder;
import arcane.gpu.IComputePass;
import arcane.gpu.IComputePipeline;
import arcane.gpu.IRenderPass;
import arcane.gpu.IRenderPipeline;
import arcane.gpu.ISampler;
import arcane.gpu.IShaderModule;
import arcane.gpu.ITexture;
import arcane.gpu.IUniformBuffer;
import arcane.gpu.IGPUDevice;
import arcane.Lib;
import arcane.Image;

@:vert({
	@:in var pos:Vec3;
	@:in var uv:Vec2;
	@:out var f_uv:Vec2;
	@:builtin(position) var position:Vec4;
	@:uniform(0) var m:Mat4; //Array<Mat4, 4>;
	// @:builtin(instanceIndex) var instanceIndex:Int;
	function main() {
		f_uv = uv;
		position = m/*[instanceIndex]*/ * vec4(pos, 1.0);
	}
})
@:frag({
	@:in var f_uv:Vec2;
	@:out var color:Vec4;
	@:uniform(1) var tex:Texture2D;
	function main() {
		color = tex.get(f_uv);
	}
})
private class MyShader extends asl.Shader {}

function main() {
	arcane.Lib.init(() -> {
		arcane.Assets.loadBytesAsync("res/parrot.png", bytes -> {
			arcane.Utils.assert(bytes != null);
			final d:IGPUDevice = cast Lib.gdriver;
			final parrot = Image.fromPngBytes(bytes).expect().toTexture(d);
			final vertex_attributes = [
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
				-1, -1, 0, 0, 1,
				 1, -1, 0, 1, 1,
				-1,  1, 0, 0, 0,
				 1, -1, 0, 1, 1,
				 1,  1, 0, 1, 0,
				-1,  1, 0, 0, 0
			]));
			final ibuf = d.createIndexBuffer({
				size: 6
			});
			ibuf.upload(0, Int32Array.fromArray([
				0, 1, 2,
				3, 4, 5
			]));

			final shader = new MyShader().make(d);
			arcane.Utils.assert(shader.vertex != null);
			arcane.Utils.assert(shader.fragment != null);

			final bind_group_layout = d.createBindGroupLayout({
				entries: [
					{
						visibility: Fragment,
						binding: 1,
						kind: Texture(Filtering)
					},
					{
						visibility: Vertex,
						binding: 0,
						kind: Buffer(false, 0)
					}
				]
			});
			final pipeline = d.createRenderPipeline({
				inputLayout: [{instanced: false, attributes: vertex_attributes}],
				vertexShader: shader.vertex,
				fragmentShader: shader.fragment,
				culling: None,
				layout: [bind_group_layout]
			});

			final sampler = d.createSampler({compare: null});

			final uniform_buffer = d.createUniformBuffer({
				size: 4 * 16 // * 4
			});

			final bind_group = d.createBindGroup({
				layout: bind_group_layout,
				entries: [
					{binding: 1, resource: Texture(parrot, sampler)},
					{
						binding: 0,
						resource: Buffer(uniform_buffer)
					}
				]});

			Lib.update.add((dt) -> {
				// var ubuf = new Float32Array(16 * 4);
				final ubuf:Float32Array = uniform_buffer.map(0, uniform_buffer.desc.size);
				// final mat = Matrix4.
				final mat = Matrix4.translation(-0.5, 0.5, 0) * Matrix4.rotation(0, Lib.time(), 0) * Matrix4.scale(0.25, 0.25, 0.25);
				mat.write(ubuf, true);
				// final mat = Matrix4.translation(0.5, 0.5, 0) * Matrix4.rotation(0, Lib.time(), 0) * Matrix4.scale(0.25, 0.25, 0.25);
				// mat.write(ubuf, true, 16);
				// final mat = Matrix4.translation(0.5, -0.5, 0) * Matrix4.rotation(0, Lib.time(), 0) * Matrix4.scale(0.25, 0.25, 0.25);
				// mat.write(ubuf, true, 32);
				// final mat = Matrix4.translation(-0.5, -0.5, 0) * Matrix4.rotation(0, Lib.time(), 0) * Matrix4.scale(0.25, 0.25, 0.25);
				// mat.write(ubuf, true, 48);
				uniform_buffer.unmap();
				// uniform_buffer.upload(0, ubuf);

				final encoder = d.createCommandEncoder();
				final pass = encoder.beginRenderPass({colorAttachments: [{texture: d.getCurrentTexture(), load: Clear, store: Store}]});
				pass.setPipeline(pipeline);
				pass.setVertexBuffer(vbuf);
				pass.setIndexBuffer(ibuf);
				pass.setBindGroup(0, bind_group);
				pass.drawInstanced(4, 0, 6);
				pass.end();
				final b = encoder.finish();
				d.submit([b]);
				d.present();
			});
		}, error -> throw error
		);
	});
}