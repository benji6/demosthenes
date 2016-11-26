#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

vec3 hsb2rgb( in vec3 c ){
  vec3 rgb = clamp(abs(mod(c.x * 6. + vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
  rgb = rgb * rgb * (3. - 2. * rgb);
  return c.z * mix(vec3(1.), rgb, c.y);
}

#define MAX_ITER 3
#define BACKGROUND_COLOR vec3(0., 0., 0.)
#define HIGHLIGHT_COLOR hsb2rgb(vec3(u_time * .1, 1., 1.))
#define TAU 6.28318530718

vec3 highlight(vec2 p, float time, float lens) {
  vec2 i = vec2(p);
  float c = 0.;
  float lensFactor = mix(1., 6., lens);
  float inten = .005 * lensFactor;

  for (int n = 0; n < MAX_ITER; n++) {
    float t = time * (1. - (3.5 / float(n+1)));
    i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
    c += 1./length(vec2(p.x / (sin(i.x+t)),p.y / (cos(i.y+t))));
  }

  c = 0.2 + c / (inten * float(MAX_ITER));
  c = 1.17-pow(c, 1.4);
  c = pow(abs(c), 8.);

  return vec3(c / sqrt(lensFactor) * HIGHLIGHT_COLOR);
}

void main() {
  vec2 st = gl_FragCoord.xy / u_resolution;
  vec2 st_square = vec2(st.x * u_resolution.x / u_resolution.y, st.y);

  float dist_center = pow(2. * length(st - .5), 2.);

  float clearness = .1 + .9 * smoothstep(0.1, 0.5, dist_center);

  vec2 p = mod(st_square * TAU, TAU) - 200.;

  vec3 color = highlight(
    p,
    u_time * 0.04 + 42.,
    smoothstep(.1, 5., dist_center)
  );

  color = color + BACKGROUND_COLOR;

  color = mix(BACKGROUND_COLOR, color, clearness);

  gl_FragColor = vec4(color, 1.);
}
