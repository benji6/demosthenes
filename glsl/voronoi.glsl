#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

vec2 random2 (vec2 st) {
  return fract(sin(vec2(dot(st, vec2(123.4, 567.8)), dot(st, vec2(876.5, 432.1)))) * 123456.789);
}

void main() {
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    st.x *= u_resolution.x/u_resolution.y;

    st *= 6.;

    vec2 i_st = floor(st);
    vec2 f_st = fract(st);

    float m_dist = 1.;

    for (int y= -1; y <= 1; y++) {
        for (int x= -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = random2(i_st + neighbor);
            point = 0.5 + 0.5 * sin(u_time * .33 + 5.4321 * point);
            vec2 diff = neighbor + point - f_st;
            float diffLength = length(diff);
            float dist = diffLength * diffLength;
            m_dist = min(m_dist, dist);
        }
    }

    vec3 color = vec3(0., m_dist * 0.6, m_dist);

    gl_FragColor = vec4(color, 1);
}
