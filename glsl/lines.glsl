precision mediump float;

uniform float u_time;
uniform sampler2D u_image;
uniform vec2 u_textureSize;
varying vec2 v_texCoord;

vec3 hsb2rgb (in vec3 c) {
  vec3 rgb = clamp(abs(mod(c.x * 6. + vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
  rgb = rgb * rgb * (3. - 2. * rgb);
  return c.z * mix(vec3(1.), rgb, c.y);
}

void main() {
  vec2 onePixel = vec2(1.0, 1.0) / u_textureSize;
  vec3 distField = vec3(1. - step(sin(u_time * .33) * .15 + .75, texture2D(u_image, v_texCoord).g));
  gl_FragColor = vec4(hsb2rgb(vec3(u_time * -.03, .9, .3)) * distField, 1.);
}
