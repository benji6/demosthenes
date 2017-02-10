# Demosthenes

This is my GLSL learnings and experiments

## Demo

[Check it out here!](https://benji6.github.io/demosthenes)


## Useful Functions

```glsl
float random (in vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.3456, 78.910))) * 12345.6789);
}
```

```glsl
vec2 random2 (vec2 st) {
  return fract(sin(vec2(dot(st, vec2(123.4, 567.8)), dot(st, vec2(876.5, 432.1)))) * 123456.789);
}
```

```glsl
vec3 hsb2rgb (in vec3 c) {
  vec3 rgb = clamp(abs(mod(c.x * 6. + vec3(0., 4., 2.), 6.) - 3.) - 1., 0., 1.);
  rgb = rgb * rgb * (3. - 2. * rgb);
  return c.z * mix(vec3(1.), rgb, c.y);
}
```

```glsl
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
```

## Resources

- [http://thebookofshaders.com](http://thebookofshaders.com)
- [http://raymarching.com](http://raymarching.com)
