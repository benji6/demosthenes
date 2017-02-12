#ifdef GL_ES
precision mediump float;
#endif

uniform float u_time;
uniform vec2 u_resolution;

const float eps = 0.005;

const int maxIterations = 64;
const float stepScale = 0.75;
const float stopThreshold = 0.005;

float sphere(in vec3 p, float radius) {
	return length(p) - radius;
}

float sinusoidBumps(in vec3 p){
  return sin(p.x*16.+u_time*.57)*cos(p.y*16.+u_time*2.17)*sin(p.z*16.-u_time*1.31) + .5*sin(p.x*32.+u_time*.07)*cos(p.y*32.+u_time*2.11)*sin(p.z*32.-u_time*1.23);
}

float scene(in vec3 p) {
  p = mod(p, 1.0) - 0.5;
	return sphere(p, .2 + .1 * abs(sin(u_time * .3))) + .05 * sinusoidBumps(p);
}

vec3 getNormal(in vec3 p) {
  float ref = scene(p);
	return normalize(vec3(
		scene(vec3(p.x+eps,p.y,p.z))-ref,
		scene(vec3(p.x,p.y+eps,p.z))-ref,
		scene(vec3(p.x,p.y,p.z+eps))-ref
	));
}

float rayMarching(vec3 origin, vec3 dir, float start, float end) {
	float sceneDist = 1e4;
	float rayDepth = start;

	for (int i = 0; i < maxIterations; i++) {
		sceneDist = scene(origin + dir * rayDepth);
		if ((sceneDist < stopThreshold) || (rayDepth >= end)) break;
		rayDepth += sceneDist * stepScale;
	}

	if (sceneDist >= stopThreshold) rayDepth = end;
	else rayDepth += sceneDist;

	return rayDepth;
}

void main() {
  vec2 aspect = vec2(u_resolution.x / u_resolution.y, 1.);
	vec2 screenCoords = (2. * gl_FragCoord.xy / u_resolution.xy - 1.) * aspect;

	vec3 lookAt = vec3(0.,0.,0.);
	vec3 camPos = vec3(1.0*sin(u_time*0.5), 0.15*sin(u_time*0.25), 1.0*cos(u_time*0.5)+u_time);

  vec3 forward = normalize(lookAt - camPos);
  vec3 right = normalize(vec3(forward.z, 0., -forward.x));
  vec3 up = normalize(cross(forward, right));

  float FOV = 0.5;

  vec3 rayOrigin = camPos;
  vec3 rayDirection = normalize(forward + FOV * screenCoords.x * right + FOV * screenCoords.y * up);

  vec3 bgcolor = vec3(.01);

	const float clipNear = 0.;
	const float clipFar = 8.;
	float dist = rayMarching(rayOrigin, rayDirection, clipNear, clipFar);

	if (dist >= clipFar) {
    gl_FragColor = vec4(bgcolor, 1.0);
    return;
	}

	vec3 surfacePosition = rayOrigin + rayDirection * dist;

	vec3 surfNormal = getNormal(surfacePosition);

	vec3 lightPos = vec3(1.0*sin(u_time*0.5), 0.15*sin(u_time*0.25), 1.0*cos(u_time*0.5)+u_time -4.);
	vec3 lightDirection = lightPos - surfacePosition;
	vec3 lcolor = vec3(.95, .97, .99);

	float lightLen = length(lightDirection);
	lightDirection /= lightLen;
	float lightAtten = min(1. / (.25 * lightLen * lightLen), 1.);

	vec3 ref = reflect(-lightDirection, surfNormal);

	vec3 sceneColor = vec3(0.);

	vec3 objColor = vec3(.3);
	float bumps = sinusoidBumps(surfacePosition);
  objColor = clamp(objColor * .8 - vec3(.1, .4, .5) * bumps, 0., 1.);

	float ambient = .5;
	float specularPower = 8.;
	float diffuse = max(0., dot(surfNormal, lightDirection));
	float specular = max(0., dot(ref, normalize(camPos - surfacePosition)));
	specular = pow(specular, specularPower);

	sceneColor += (objColor*(diffuse*0.8+ambient)+specular*0.5)*lcolor*lightAtten;

	gl_FragColor = vec4(clamp(sceneColor, 0., 1.), 1.);
}
