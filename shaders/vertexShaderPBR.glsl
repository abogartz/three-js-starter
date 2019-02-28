varying vec3 v_Position;
varying vec2 v_UV;
varying vec3 v_Normal;
varying vec3 vViewDir;
varying vec3 v_Camera;

void main()
{
  vec4 pos = modelViewMatrix * vec4(position, 1.0);
  v_Position = vec3(pos.xyz) / pos.w;
  v_Normal = normalize(vec3(modelViewMatrix * vec4(normal.xyz, 0.0)));
  vViewDir = normalize(position - cameraPosition);   
  v_UV = uv;
  v_Camera = cameraPosition;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

