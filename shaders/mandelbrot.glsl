#ifdef GL_ES
precision mediump float;
#endif

#define MAX_ITER 127
#define TAU 6.28318530718
#define ZOOM_CENTER vec2(-.559, .62)
#define ZOOM_SIZE .08

uniform vec2 u_resolution;
uniform float u_time;

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
  return a+b*cos(TAU*(c*t+d));
}

vec2 f(vec2 z, vec2 c) {
  return mat2(z,-z.y,z.x) * z + c;
}

void main() {
  int iterations;
  vec2 st = gl_FragCoord.xy / u_resolution;
  vec2 st_square = vec2(st.x * u_resolution.x / u_resolution.y, st.y);
  vec2 c = ZOOM_CENTER + (st_square * 4.0 - vec2(2.0)) * (ZOOM_SIZE / 4.0);
  vec2 z = vec2(0.);
  bool unbounded = false;

  for (int i = 0; i < 10000; i++) {
    if (i > MAX_ITER) break;
    iterations = i;
    z = f(z, c);
    if (length(z) > 2.) {
      unbounded = true;
      break;
    }
  }

  gl_FragColor = unbounded
    ? vec4(palette(
      float(iterations) / float(MAX_ITER),
      vec3(0., .9, .7),
      vec3(.05, .66, .72),
      vec3(.94, 1., .53),
      vec3(.84, .44 * abs(cos(u_time*.3)), .39 * abs(sin(u_time * .2)))
    ), 1.)
    : vec4(vec3(.0), 1.);
}
