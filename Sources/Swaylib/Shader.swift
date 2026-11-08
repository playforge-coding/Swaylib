import CRaylib

/// The shading language a backend compiles.
public enum ShaderLanguage: Sendable {
    /// GLSL 330, for desktop OpenGL 3.3 (the default backend).
    case glsl330
    /// GLSL ES 300, for OpenGL ES 3 (the `ANGLE` trait).
    case glslES300
}

/// A GPU shader program. Unloaded when it goes out of scope.
///
/// Shader source differs between backends: desktop OpenGL takes GLSL 330, ANGLE takes GLSL ES 300.
/// Pick the source with ``language``. Pass nil for either stage to use raylib's default.
///
/// Uniform setters take effect at once, but raylib batches draws and submits them later, so every
/// draw it has not submitted yet uses the last value set. Set a uniform before the draws that use
/// it; to draw with different values in one frame, give each value its own ``shaderMode(_:_:)``
/// call, since ending one submits the draws made in it.
@MainActor
public struct Shader: ~Copyable {
    var raw: CRaylib.Shader
    private let context = GraphicsContext.generation
    /// False when raylib handed back its own default program (no stages asked for), whose locations
    /// array it owns.
    private let ownsProgram: Bool

    /// The shading language of the backend Swaylib was built with.
    ///
    /// Use this rather than `#if ANGLE` in your own code: package traits only define compilation
    /// conditions inside the package that declares them, so Swaylib's `ANGLE` trait is not visible
    /// as a condition in a package that depends on it.
    public nonisolated static var language: ShaderLanguage {
        #if ANGLE
        .glslES300
        #else
        .glsl330
        #endif
    }

    /// Loads and compiles a shader from source files.
    ///
    /// - Throws: ``SwaylibError/loadFailed(_:source:)`` if a file cannot be read or the program does
    ///   not compile or link. (raylib itself treats an unreadable file as a missing stage and uses
    ///   its default for it.)
    public init(vertexPath: String?, fragmentPath: String?) throws(SwaylibError) {
        try self.init(
            vertexCode: Self.readSource(vertexPath), fragmentCode: Self.readSource(fragmentPath),
            source: [vertexPath, fragmentPath].compactMap { $0 }.joined(separator: ", "))
    }

    /// Compiles a shader from source code.
    ///
    /// - Throws: ``SwaylibError/loadFailed(_:source:)`` if the program does not compile or link.
    public init(vertexCode: String?, fragmentCode: String?) throws(SwaylibError) {
        try self.init(vertexCode: vertexCode, fragmentCode: fragmentCode, source: "shader code")
    }

    private init(vertexCode: String?, fragmentCode: String?, source: String) throws(SwaylibError) {
        let raw = LoadShaderFromMemory(vertexCode, fragmentCode)
        let stagesSupplied = vertexCode != nil || fragmentCode != nil
        // raylib hands back its default program when it ends up with no custom stage at all. That
        // is fine when the caller asked for no stages, and a failure when it supplied one.
        let isDefault = raw.id == rlGetShaderIdDefault()
        guard IsShaderValid(raw), !(stagesSupplied && isDefault) else { throw .loadFailed(.shader, source: source) }
        self.raw = raw
        self.ownsProgram = !isDefault
    }

    /// The text of a shader file, or nil when no file was given.
    private static func readSource(_ path: String?) throws(SwaylibError) -> String? {
        guard let path else { return nil }
        guard let text = LoadFileText(path) else { throw .loadFailed(.shader, source: path) }
        defer { UnloadFileText(text) }
        return String(cString: text)
    }

    deinit {
        if GraphicsContext.isCurrent(context) {
            UnloadShader(raw)
        } else if ownsProgram {
            // The program went with its window's context; only the locations array is left.
            MemFree(raw.locs)
        }
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
