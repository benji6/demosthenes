const fragShaderNames = [
  'mandelbrot',
  'noise',
  'smoke',
]

const selectedFragShaderIndex = 0

const createShader = (gl, type, source) => {
  const shader = gl.createShader(type)
  gl.shaderSource(shader, source)
  gl.compileShader(shader)
  if (gl.getShaderParameter(shader, gl.COMPILE_STATUS)) return shader
  console.error(gl.getShaderInfoLog(shader))
  gl.deleteShader(shader)
}

const createProgram = (gl, vertexShader, fragmentShader) => {
  const program = gl.createProgram()
  gl.attachShader(program, vertexShader)
  gl.attachShader(program, fragmentShader)
  gl.linkProgram(program)
  if (gl.getProgramParameter(program, gl.LINK_STATUS)) return program
  console.error(gl.getProgramInfoLog(program))
  gl.deleteProgram(program)
}

const gl = document.querySelector('canvas').getContext('webgl')
gl.canvas.width = innerWidth
gl.canvas.height = innerHeight

fetch(`shaders/${fragShaderNames[selectedFragShaderIndex]}.glsl`)
  .then(response => response.text())
  .then(fragmentShaderSource => {
    const vertexShader = createShader(gl, gl.VERTEX_SHADER, 'attribute vec4 a_position;void main(){gl_Position=a_position;}')
    const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource)
    const program = createProgram(gl, vertexShader, fragmentShader)
    const positionAttributeLocation = gl.getAttribLocation(program, 'a_position')
    const positionBuffer = gl.createBuffer()

    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)

    const vertices = new Float32Array([
      -1, -1, -1, 1, 1, 1,
      -1, -1, 1, 1, 1, -1,
    ])

    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW)
    gl.enableVertexAttribArray(positionAttributeLocation)
    gl.vertexAttribPointer(positionAttributeLocation, 2, gl.FLOAT, false, 0, 0)
    gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)
    gl.useProgram(program)

    const uResolutionLocation = gl.getUniformLocation(program, 'u_resolution')
    const uTimeLocation = gl.getUniformLocation(program, 'u_time')

    ;(function render () {
      requestAnimationFrame(render)
      gl.uniform1f(uTimeLocation, performance.now() / 1000)
      gl.uniform2fv(uResolutionLocation, [gl.canvas.width, gl.canvas.height])
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, vertices.length / 2)
    }())
})

onresize = () => gl.viewport(0, 0, gl.canvas.width = innerWidth, gl.canvas.height = innerHeight)
