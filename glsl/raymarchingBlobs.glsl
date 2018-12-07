#ifdef GL_ES
precision mediump float;
#endif

uniform float u_time;
uniform vec2 u_resolution;

const float eps = 0.005;

float sphere(in vec3 p, float radius) {
	return length(p) - radius;
}

float sinusoidalPlasma(in vec3 p){
  return sin(p.x+u_time*2.)*cos(p.y+u_time*2.1)*sin(p.z+u_time*2.3) + 0.25*sin(p.x*2.)*cos(p.y*2.)*sin(p.z*2.);
}

float sinusoidBumps(in vec3 p){
  return sin(p.x*16.+u_time*.57)*cos(p.y*16.+u_time*2.17)*sin(p.z*16.-u_time*1.31) + .5*sin(p.x*32.+u_time*.07)*cos(p.y*32.+u_time*2.11)*sin(p.z*32.-u_time*1.23);
}

float scene(in vec3 p) {
  p = mod(p, 1.) - 0.5;
	return sphere(p, .2 + .1 * abs(sin(u_time * .3))) + .05 * sinusoidBumps(p);
}

vec3 getNormal(in vec3 p) {
  vec2 e = vec2(-.5 * eps, .5 * eps);
  return normalize(e.yxx*scene(p+e.yxx)+e.xxy*scene(p+e.xxy)+e.xyx*scene(p+e.xyx)+e.yyy*scene(p+e.yyy));
}

float rayMarching(vec3 origin, vec3 dir, float start, float end) {
  const float stopThreshold = 0.005;
	float sceneDist = 1e4;
	float rayDepth = start;

	for (int i = 0; i < 64; i++) {
		sceneDist = scene(origin + dir * rayDepth);
		if ((sceneDist < stopThreshold) || (rayDepth >= end)) break;
		rayDepth += sceneDist * .8;
	}

	if (sceneDist >= stopThreshold) rayDepth = end;
	else rayDepth += sceneDist;

	return rayDepth;
}

vec3 lighting(vec3 surfacePosition, vec3 camPos, int reflectionPass){
    vec3 sceneColor = vec3(0.);
    vec3 voxPos = mod(surfacePosition*.25, 1.);
    vec3 objColor = vec3(.3);

    if ((voxPos.x<0.5)&&(voxPos.y>=0.5)&&(voxPos.z<0.5)) objColor = vec3(voxPos.x,voxPos.z,.5) * .33;
    else if ((voxPos.x>=0.5)&&(voxPos.y<0.5)&&(voxPos.z>=0.5)) objColor = vec3(voxPos.y,.5,voxPos.z) * .33;

    float bumps = sinusoidBumps(surfacePosition);
    objColor = clamp(objColor * .8 - vec3(.1, .4, .5) * bumps, 0., 1.);

    float fakeShadowMovement = sinusoidalPlasma(surfacePosition * 8.);
    objColor = clamp(objColor*(.75-.25*fakeShadowMovement), 0., 1.);

    vec3 surfNormal = getNormal(surfacePosition);

    vec3 lightPosition = vec3(0., 1., 0. + u_time);
    vec3 lightDirection = lightPosition - surfacePosition;

    float len = length(lightDirection);
    lightDirection /= len;
    float lightAtten = min(1. / (.25 * len * len), 1.);

    vec3 ref = reflect(-lightDirection, surfNormal);

    float ambientOcclusion = 1.;

    float ambient = .25;
    float specularPower = 128.;
    float diffuse = max(0., dot(surfNormal, lightDirection));
    float specular = max(0., dot(ref, normalize(camPos-surfacePosition)));
    specular = pow(specular, specularPower);

    sceneColor += (objColor*(diffuse*.8+ambient)+specular*.5)*lightAtten*ambientOcclusion;

    return clamp(sceneColor, 0., 1.);
}

void main() {
  vec2 aspect = vec2(u_resolution.x / u_resolution.y, 1.);
	vec2 screenCoords = (2. * gl_FragCoord.xy / u_resolution.xy - 1.) * aspect;

	vec3 lookAt = vec3(0., 1. * sin(u_time * .5), u_time);
	vec3 camPos = vec3(1.0*sin(u_time*0.5), 0.15*sin(u_time*0.25), 1.0*cos(u_time*0.5)+u_time);

  vec3 forward = normalize(lookAt - camPos);
  vec3 right = normalize(vec3(forward.z, 0., -forward.x));
  vec3 up = normalize(cross(forward, right));

  float FOV = 0.5;

  vec3 rayOrigin = camPos;
  vec3 rayDirection = normalize(forward + FOV * screenCoords.x * right + FOV * screenCoords.y * up);

	const float clipFar = 8.0;
	float dist = rayMarching(rayOrigin, rayDirection, 0., clipFar);

	if (dist >= clipFar) {
    gl_FragColor = vec4(vec3(.01), 1.0);
    return;
	}

	vec3 surfacePosition = rayOrigin + rayDirection * dist;

	gl_FragColor = vec4(lighting(surfacePosition, camPos, 0), 1.);
}
