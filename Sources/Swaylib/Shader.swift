import CRaylib

/// A GPU shader program. Unloaded when it goes out of scope.
///
/// Shader source differs between backends: desktop OpenGL takes GLSL 330, ANGLE takes GLSL ES 300.
/// Pass nil for either stage to use raylib's default.
@MainActor
public struct Shader: ~Copyable {
    var raw: CRaylib.Shader

    /// Loads and compiles a shader from source files.
    public init(vertexPath: String?, fragmentPath: String?) throws(SwaylibError) {
        let raw = LoadShader(vertexPath, fragmentPath)
        guard IsShaderValid(raw) else {
            throw .loadFailed(.shader, source: [vertexPath, fragmentPath].compactMap { $0 }.joined(separator: ", "))
        }
        self.raw = raw
    }

    /// Compiles a shader from source code.
    public init(vertexCode: String?, fragmentCode: String?) throws(SwaylibError) {
        let raw = LoadShaderFromMemory(vertexCode, fragmentCode)
        guard IsShaderValid(raw) else { throw .loadFailed(.shader, source: "shader code") }
        self.raw = raw
    }

    deinit {
        UnloadShader(raw)
    }

    /// The OpenGL program id.
    public var id: UInt32 {
        raw.id
    }

    /// The location of a uniform, or nil if the shader has no such uniform.
    public func location(ofUniform name: String) -> Int32? {
        let location = GetShaderLocation(raw, name)
        return location >= 0 ? location : nil
    }

    /// The location of a vertex attribute, or nil if the shader has no such attribute.
    public func location(ofAttribute name: String) -> Int32? {
        let location = GetShaderLocationAttrib(raw, name)
        return location >= 0 ? location : nil
    }

    /// The location raylib uses for one of its standard inputs.
    public func location(of index: ShaderLocationIndex) -> Int32 {
        raw.locs[Int(index.rawValue)]
    }

    /// Tells raylib which location to use for one of its standard inputs.
    public func setLocation(of index: ShaderLocationIndex, to location: Int32) {
        raw.locs[Int(index.rawValue)] = location
    }

    /// Sets a `float` uniform.
    public func setFloat(_ value: Float, at location: Int32) {
        var value = value
        SetShaderValue(raw, location, &value, ShaderUniformDataType.float.rawValue)
    }

    /// Sets an `int` uniform.
    public func setInt(_ value: Int32, at location: Int32) {
        var value = value
        SetShaderValue(raw, location, &value, ShaderUniformDataType.int.rawValue)
    }

    /// Sets a `vec2` uniform.
    public func setVector(_ value: Vector2, at location: Int32) {
        var value = value.raw
        SetShaderValue(raw, location, &value, ShaderUniformDataType.vec2.rawValue)
    }

    /// Sets a `vec3` uniform.
    public func setVector(_ value: Vector3, at location: Int32) {
        var value = value.raw
        SetShaderValue(raw, location, &value, ShaderUniformDataType.vec3.rawValue)
    }

    /// Sets a `vec4` uniform.
    public func setVector(_ value: Vector4, at location: Int32) {
        var value = value.raw
        SetShaderValue(raw, location, &value, ShaderUniformDataType.vec4.rawValue)
    }

    /// Sets a `mat4` uniform.
    public func setMatrix(_ value: Matrix, at location: Int32) {
        SetShaderValueMatrix(raw, location, value.raw)
    }

    /// Binds a texture to a `sampler2D` uniform.
    public func setTexture(_ texture: borrowing Texture, at location: Int32) {
        SetShaderValueTexture(raw, location, texture.raw)
    }

    /// Sets a `float[]` uniform.
    public func setFloats(_ values: [Float], at location: Int32) {
        values.withUnsafeBufferPointer {
            SetShaderValueV(raw, location, $0.baseAddress, ShaderUniformDataType.float.rawValue, Int32($0.count))
        }
    }
}
