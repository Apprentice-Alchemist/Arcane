import arcane.util.Color;
import arcane.util.Math;
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

function main() {
	arcane.Lib.init(() -> {
		arcane.Assets.loadBytesAsync("res/parrot.png", bytes -> {
			trace(bytes);
			arcane.Utils.assert(bytes != null);
			final d:IGPUDevice = cast Lib.gdriver;
			final parrot = Image.fromPngBytes(bytes).expect().toTexture(d);
			final vertex_attributes = vertex_attribs("pos" => Float3, /*"uv" => Float2,*/ "normal" => Float3);
			final vbuf = d.createVertexBuffer({
				size: Std.int(CUBE_VERTICES.length / 6),
				instanceDataStepRate: 0,
				attributes: vertex_attributes
			});
			vbuf.upload(0, Float32Array.fromArray(CUBE_VERTICES));
			// vbuf.upload(0, Float32Array.fromArray([
			// 	-1, -1, 0, 0, 1, 0, 0, 0,
			// 	 1, -1, 0, 1, 1, 0, 0, 0,
			// 	-1,  1, 0, 0, 0, 0, 0, 0,
			// 	 1, -1, 0, 1, 1, 0, 0, 0,
			// 	 1,  1, 0, 1, 0, 0, 0, 0,
			// 	-1,  1, 0, 0, 0, 0, 0, 0,
			// ]));
			final ibuf = d.createIndexBuffer({
				size: Std.int(CUBE_VERTICES.length / 6)
			});
			ibuf.upload(0, Int32Array.fromArray([
				for(i in 0...ibuf.desc.size) i
				// 0, 1, 2,
				// 3, 4, 5
			]));

			final shader = new LightingShader().make(d);
			arcane.Utils.assert(shader.vertex != null);
			arcane.Utils.assert(shader.fragment != null);

			final bind_group_layout = d.createBindGroupLayout({
				entries: [
					{
						visibility: Fragment,
						binding: 2,
						kind: Buffer(false, 0)
					},
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
				layout: [bind_group_layout],
				depthWrite: true,
				depthTest: LessEqual
			});

			final sampler = d.createSampler({});

			final vertex_uniform_buffer = d.createUniformBuffer({
				size: 4 * 16 * 4
			});

			final fragment_uniform_buffer = d.createUniformBuffer({
				size: 3 * 4 * 4
			});

			final bind_group = d.createBindGroup({
				layout: bind_group_layout,
				entries: [
					{binding: 2, resource: Buffer(fragment_uniform_buffer)},
					{binding: 1, resource: Texture(parrot, sampler)},
					{
						binding: 0,
						resource: Buffer(vertex_uniform_buffer)
					}
				]});

			var camera = new Camera(new Vector3(0,0,3),new Vector3(0,1,0), -90, 0.0);

			Lib.update.add((dt) -> {
				final projection = Matrix4.homogeneousPerspective(Math.PI * camera.zoom, Lib.system.width() / Lib.system.height(), 0.001, 100);
				final view = Matrix4.translation(0, 0, -2); // camera.getViewMatrix();
				final model = Matrix4.rotation(Lib.time(), 0, 0);
				final ubuf:Float32Array = vertex_uniform_buffer.map(0, vertex_uniform_buffer.desc.size);
				// Matrix4.identity()
				model.write(ubuf, true);
				view.write(ubuf, true, 16);
				projection.write(ubuf, true, 32);
				// final mat = Matrix4.translation(-0.5, 0.5, 0) * Matrix4.rotation(Lib.time(), Lib.time(), Lib.time()) * Matrix4.scale(0.25, 0.25, 0.25);
				// mat.write(ubuf, true);
				// final mat = Matrix4.translation(0.5, 0.5, 0) * Matrix4.rotation(0, Lib.time(), 0) * Matrix4.scale(0.25, 0.25, 0.25);
				// mat.write(ubuf, true, 16);
				// final mat = Matrix4.translation(0.5, -0.5, 0) * Matrix4.rotation(0, Lib.time(), 0) * Matrix4.scale(0.25, 0.25, 0.25);
				// mat.write(ubuf, true, 32);
				// final mat = Matrix4.translation(-0.5, -0.5, 0) * Matrix4.rotation(0, Lib.time(), 0) * Matrix4.scale(0.25, 0.25, 0.25);
				// mat.write(ubuf, true, 48);
				vertex_uniform_buffer.unmap();

				final ubuf:Float32Array = fragment_uniform_buffer.map(0, fragment_uniform_buffer.desc.size);
				ubuf[0] = 1.2;
				ubuf[1] = 1.0;
				ubuf[2] = 2.0;
				ubuf[3] = 1.0;
				
				ubuf[4] = 0.0;
				ubuf[5] = 0.0;
				ubuf[6] = 0.0;
				ubuf[7] = 1.0;

				ubuf[8] = 1.0;
				ubuf[9] = 1.0;
				ubuf[10] = 1.0;
				ubuf[11] = 1.0;
				fragment_uniform_buffer.unmap();

				final encoder = d.createCommandEncoder();
				final pass = encoder.beginRenderPass({
					colorAttachments: [{texture: d.getCurrentTexture(), load: Clear(), store: Store}]
				});
				pass.setPipeline(pipeline);
				pass.setVertexBuffer(vbuf);
				pass.setIndexBuffer(ibuf);
				pass.setBindGroup(0, bind_group);
				pass.draw(0, Std.int(CUBE_VERTICES.length / 6));
				pass.end();
				final b = encoder.finish();
				d.submit([b]);
				d.present();
			});
		}, error -> trace(error)
		);
	});
}

var CUBE_VERTICES = [
        -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
         0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
         0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
         0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
        -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
        -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,

        -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,
         0.5, -0.5,  0.5,  0.0,  0.0,  1.0,
         0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
         0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
        -0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
        -0.5, -0.5,  0.5,  0.0,  0.0,  1.0,

        -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,
        -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,
        -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
        -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
        -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,
        -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,

         0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
         0.5,  0.5, -0.5,  1.0,  0.0,  0.0,
         0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
         0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
         0.5, -0.5,  0.5,  1.0,  0.0,  0.0,
         0.5,  0.5,  0.5,  1.0,  0.0,  0.0,

        -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
         0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
         0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
         0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
        -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
        -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,

        -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
         0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
         0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
         0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
        -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
        -0.5,  0.5, -0.5,  0.0,  1.0,  0.0
];
