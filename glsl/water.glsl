#ifdef GL_ES
precision mediump float;
#endif

#define OCTAVES 6

uniform vec2 u_resolution;
uniform float u_time;

float random (in vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.3456, 78.910))) * 12345.6789);
}

float noise (in vec2 st) {
  vec2 i = floor(st);
  vec2 f = fract(st);

  float a = random(i);
  float b = random(i + vec2(1., 0.));
  float c = random(i + vec2(0., 1.));
  float d = random(i + vec2(1., 1.));

  vec2 u = f * f * (3. - 2. * f);

  return mix(a, b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;
}

float fbm (in vec2 st) {
  float v = 0.;
  float a = .5;
  for (int i = 0; i < OCTAVES; i++) {
      v += a * noise(st);
      st *= 2.;
      a *= .67;
  }
  return v;
}

void main() {
  vec2 st = gl_FragCoord.xy / u_resolution.xy;
  st.x *= u_resolution.x / u_resolution.y;
  vec3 color = vec3(0.);

  vec2 q = vec2(fbm(st), fbm(st + vec2(1.)));

  vec2 r = vec2(0.);
  r.x = fbm(st + 1. * q + vec2(1.7, 9.2)+ .05 * u_time);
  r.y = fbm(st + 1. * q + vec2(8.3, 2.8)+ .046 * u_time);

  float f = fbm(st + r);

  color = mix(vec3(0.101961,0.619608,0.666667),
              vec3(0.666667,0.666667,0.498039),
              clamp(f * f * 4., 0., 1.));

  color = mix(color, vec3(0, 0, 0.164706), clamp(length(q), 0., 1.));

  color = mix(color, vec3(0.25, .6, 1.), clamp(length(r.x), 0., 1.));

  gl_FragColor = vec4((f * f * f + .6 * f * f + .5 * f) * color, 1.);
}
