precision mediump float;

uniform float u_kernel[9];
uniform float u_kernelWeight;
uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_image;
uniform vec2 u_textureSize;
varying vec2 v_texCoord;

void main() {
  vec2 st = gl_FragCoord.xy / u_resolution;
  vec2 onePixel = vec2(1., 1.) / u_textureSize;
  vec4 colorSum =
    texture2D(u_image, v_texCoord + onePixel * vec2(-1, -1)) * u_kernel[0] +
    texture2D(u_image, v_texCoord + onePixel * vec2( 0, -1)) * u_kernel[1] +
    texture2D(u_image, v_texCoord + onePixel * vec2( 1, -1)) * u_kernel[2] +
    texture2D(u_image, v_texCoord + onePixel * vec2(-1,  0)) * u_kernel[3] +
    texture2D(u_image, v_texCoord + onePixel * vec2( 0,  0)) * u_kernel[4] +
    texture2D(u_image, v_texCoord + onePixel * vec2( 1,  0)) * u_kernel[5] +
    texture2D(u_image, v_texCoord + onePixel * vec2(-1,  1)) * u_kernel[6] +
    texture2D(u_image, v_texCoord + onePixel * vec2( 0,  1)) * u_kernel[7] +
    texture2D(u_image, v_texCoord + onePixel * vec2( 1,  1)) * u_kernel[8];

  gl_FragColor = vec4(vec3(st.y, st.x, abs(sin(u_time * .3))) * (colorSum / u_kernelWeight).rgb, 1.0);
}
