#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

vec3 hsb2rgb(float x, float y, float z) {
  vec3 rgb = clamp(abs(mod(x * 6. + vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
  rgb = rgb * rgb * (3. - 2. * rgb);
  return z * mix(vec3(1.), rgb, y);
}

void main() {
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    st.x *= u_resolution.x/u_resolution.y;

    float count = 32.5;
    float distance_field = step(mod(st.x, 1. / count), .5 / count) * step(mod(st.y, 1. / count), .5 / count);

    float hue = st.x * 8. + st.y * 3.33 - u_time / 2.;
    vec3 color_field = hsb2rgb(hue, .667, 1.);

    gl_FragColor = vec4(color_field * distance_field, 1);
}
