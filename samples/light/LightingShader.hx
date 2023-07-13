@:vert({
	@:in var pos:Vec3;
	// @:in var uv:Vec2;
	@:in var normal:Vec3;
	@:out var f_pos:Vec4;
	// @:out var f_uv:Vec2;
	@:out var f_normal:Vec3;
	@:builtin(position) var position:Vec4;
	@:uniform(0) var model:Mat4;
	@:uniform(0) var view:Mat4;
	@:uniform(0) var projection:Mat4;
	// @:builtin(instanceIndex) var instanceID:Int;
	// @:uniform(0) var m:Array<Mat4, 4>;
	// @:uniform(0) var mInvT:Mat4;
	function main() {
		// f_pos = vec4(pos, 1.0);
		// f_normal = normal;
		// position = vec4(pos, 1.0);
		f_pos = model * vec4(pos, 1.0);
		// f_uv = uv;
		f_normal = mat3(transpose(inverse(model))) * normal;
		position = projection * view * model * vec4(pos, 1.0);
	}
})
@:frag({
	@:in var f_pos:Vec4;
	// @:in var f_uv:Vec2;
	@:in var f_normal:Vec3;
	@:out var color:Vec4;
	@:uniform(1) var tex:Texture2D;
	@:uniform(2) var lightPos:Vec4;
	@:uniform(2) var viewPos:Vec4;
	@:uniform(2) var lightColor:Vec4;
	// @:uniform(2) var objectColor:Vec4;
	function main() {
		// 	    // ambient
		// float ambientStrength = 0.1;
		// vec3 ambient = ambientStrength * lightColor;
		// // diffuse
		// vec3 norm = normalize(Normal);
		// vec3 lightDir = normalize(lightPos - FragPos);
		// float diff = max(dot(norm, lightDir), 0.0);
		// vec3 diffuse = diff * lightColor;
		// // specular
		// float specularStrength = 0.5;
		// vec3 viewDir = normalize(viewPos - FragPos);
		// vec3 reflectDir = reflect(-lightDir, norm);
		// float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
		// vec3 specular = specularStrength * spec * lightColor;
		// vec3 result = (ambient + diffuse + specular) * objectColor;
		// FragColor = vec4(result, 1.0);
		var lightColor3 = lightColor.xyz;
		var viewPos3 = viewPos.xyz;
		var lightPos3 = lightPos.xyz;
		var objectColor = vec3(1.0, 0.0, 0.0); // tex.get(f_uv).xyz; // objectColor.xyz;
		var ambientStrength = 0.1;
		var ambient = ambientStrength * lightColor3;
		var norm = normalize(f_normal);
		var lightDir = normalize(lightPos3 - f_pos.xyz);
		var diff = max(dot(norm, lightDir), 0.0);
		var diffuse = diff * lightColor3;
		var specularStrength = 0.5;
		var viewDir = normalize(viewPos3 - f_pos.xyz);
		var reflectDir = reflect(-lightDir, norm);
		var spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
		var specular = specularStrength * spec * lightColor3;
		var result = (ambient + diffuse + specular) * objectColor; //tex.get(f_uv).xyz;
		color = vec4(result, 1.0);
		// color = vec4(lightColor, 1.0);
		// color = vec4(lightColor.xyz + lightPos + viewPos, 1.0);
		// color = vec4(lightColor3, 1.0);
		// color = tex.get(f_uv);
		// color.w = 1.0;
		// color = mix(vec4(result, 1.0), vec4(1.0, 0.0, 0.0, 1.0), 0.5);
	}
})
class LightingShader extends asl.Shader {}