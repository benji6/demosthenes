import manifests from "./manifests.js";

let animationFrameId;
let fragShaderIndex;

const createShader = (gl, type, source) => {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (gl.getShaderParameter(shader, gl.COMPILE_STATUS)) return shader;
  console.error(gl.getShaderInfoLog(shader));
  gl.deleteShader(shader);
};

const createProgram = (gl, vertexShader, fragmentShader) => {
  const program = gl.createProgram();
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  if (gl.getProgramParameter(program, gl.LINK_STATUS)) return program;
  console.error(gl.getProgramInfoLog(program));
  gl.deleteProgram(program);
};

const gl = document.querySelector("canvas").getContext("webgl");
gl.canvas.width = innerWidth;
gl.canvas.height = innerHeight;

const runShader = (fragShaderIndex) => {
  const fragShader = manifests[fragShaderIndex];

  const promises = [
    fetch("glsl/vert.glsl").then((response) => response.text()),
    fetch(`glsl/${fragShader}.glsl`).then((response) => response.text()),
  ];

  Promise.all(promises).then(([vertexShaderSrc, fragmentShaderSrc, img]) => {
    const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSrc);
    const fragmentShader = createShader(
      gl,
      gl.FRAGMENT_SHADER,
      fragmentShaderSrc
    );
    const program = createProgram(gl, vertexShader, fragmentShader);
    const positionAttributeLocation = gl.getAttribLocation(
      program,
      "a_position"
    );
    const positionBuffer = gl.createBuffer();

    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);

    const vertices = new Float32Array([
      -1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1,
    ]);

    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
    gl.enableVertexAttribArray(positionAttributeLocation);
    gl.vertexAttribPointer(positionAttributeLocation, 2, gl.FLOAT, false, 0, 0);
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
    gl.useProgram(program);

    const uResolutionLocation = gl.getUniformLocation(program, "u_resolution");
    const uTimeLocation = gl.getUniformLocation(program, "u_time");

    cancelAnimationFrame(animationFrameId);

    if (img) {
      const computeKernelWeight = (kernel) => {
        const weight = kernel.reduce((a, b) => a + b);
        return weight <= 0 ? 1 : weight;
      };

      const kernelLocation = gl.getUniformLocation(program, "u_kernel[0]");
      const kernelWeightLocation = gl.getUniformLocation(
        program,
        "u_kernelWeight"
      );

      const edgeDetectKernel = [-1, -1, -1, -1, 16, -1, -1, -1, -1];

      gl.uniform1fv(kernelLocation, edgeDetectKernel);
      gl.uniform1f(kernelWeightLocation, computeKernelWeight(edgeDetectKernel));

      // HACK i don't understand this and it's horrible
      setTimeout(() => {
        const textureSizeLocation = gl.getUniformLocation(
          program,
          "u_textureSize"
        );
        const texCoordLocation = gl.getAttribLocation(program, "a_texCoord");
        const texCoordBuffer = gl.createBuffer();
        gl.uniform2f(textureSizeLocation, img.width, img.height);
        gl.bindBuffer(gl.ARRAY_BUFFER, texCoordBuffer);
        gl.bufferData(
          gl.ARRAY_BUFFER,
          new Float32Array([0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1]),
          gl.STATIC_DRAW
        );
        gl.enableVertexAttribArray(texCoordLocation);
        gl.vertexAttribPointer(texCoordLocation, 2, gl.FLOAT, false, 0, 0);

        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

        gl.texImage2D(
          gl.TEXTURE_2D,
          0,
          gl.RGBA,
          gl.RGBA,
          gl.UNSIGNED_BYTE,
          img
        );
      }, 100);
    }

    (function render() {
      animationFrameId = requestAnimationFrame(render);
      gl.uniform1f(uTimeLocation, performance.now() / 1000);
      gl.uniform2fv(uResolutionLocation, [gl.canvas.width, gl.canvas.height]);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, vertices.length / 2);
    })();
  });
};

window.onhashchange = () => {
  fragShaderIndex = !location.hash ? 0 : Number(location.hash.slice(1));
  if (!manifests[fragShaderIndex]) {
    location.hash = 0;
    fragShaderIndex = 0;
  }

  runShader(fragShaderIndex);
};

window.onhashchange();

const navigateLeft = () =>
  (location.hash = !fragShaderIndex
    ? manifests.length - 1
    : fragShaderIndex - 1);
const navigateRight = () =>
  (location.hash =
    fragShaderIndex === manifests.length - 1 ? 0 : fragShaderIndex + 1);

let xDown = null;
let yDown = null;

const handleTouchStart = (e) => {
  xDown = e.touches[0].clientX;
  yDown = e.touches[0].clientY;
};

const handleTouchMove = (e) => {
  if (!xDown || !yDown) return;

  const xUp = e.touches[0].clientX;
  const yUp = e.touches[0].clientY;

  const xDiff = xDown - xUp;
  const yDiff = yDown - yUp;

  if (Math.abs(xDiff) > Math.abs(yDiff)) {
    if (xDiff > 0) navigateLeft();
    else navigateRight();
  } else if (yDiff > 0) navigateRight();
  else navigateLeft();

  xDown = null;
  yDown = null;
};

document.addEventListener("touchstart", handleTouchStart);
document.addEventListener("touchmove", handleTouchMove);

document.onkeydown = (e) => {
  switch (e.keyCode) {
    // left
    case 37:
    case 65:
    // down
    case 40:
    case 83:
      return navigateLeft();
    // right
    case 39:
    case 68:
    // up
    case 38:
    case 87:
      return navigateRight();
  }
};

onresize = () =>
  gl.viewport(
    0,
    0,
    (gl.canvas.width = innerWidth),
    (gl.canvas.height = innerHeight)
  );
