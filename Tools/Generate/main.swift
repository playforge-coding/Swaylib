import Foundation

// swaylib-generate: writes the mechanical parts of the Swift API from raylib's parser output.
//
//   swift run swaylib-generate           regenerate the files under Sources/Swaylib
//   swift run swaylib-generate --check   exit 1 if the committed files are out of date

let packageRoot = URL(filePath: #filePath)
    .deletingLastPathComponent()  // main.swift
    .deletingLastPathComponent()  // Generate
    .deletingLastPathComponent()  // Tools
let toolDirectory = packageRoot.appending(path: "Tools/Generate")
// raylib's own parser output, from the submodule, so it always matches the raylib being built.
let apiFile = packageRoot.appending(path: "Sources/CRaylib/raylib/tools/rlparser/output/raylib_api.json")
let wrappedFile = toolDirectory.appending(path: "wrapped.txt")

let outputs: [(path: String, content: () throws -> String)] = [
    ("Sources/Swaylib/Generated/Enums.swift", { emitEnums(api) }),
    ("Sources/Swaylib/Generated/Colors.swift", { try emitColors(api) }),
    ("Sources/Swaylib/Swaylib.docc/APICoverage.md", { try emitCoverage(api, wrapped: wrapped, version: version) }),
    ("Sources/CRaylib/metal/rcore.c", { try emitMetalCore(root: packageRoot) }),
    ("Sources/CRaylib/metal/rcore_desktop_rgfw.c", { try emitMetalPlatform(root: packageRoot) }),
]

let check = CommandLine.arguments.contains("--check")

let api: API
let wrapped: [String: String]
let version: String
do {
    api = try API.load(from: apiFile)
    wrapped = try parseWrapped(try String(contentsOf: wrappedFile, encoding: .utf8), api: api)
    version = try raylibVersion(api)
} catch {
    fail("swaylib-generate: \(error)")
}

var outOfDate: [String] = []
for output in outputs {
    let url = packageRoot.appending(path: output.path)
    do {
        let content = try output.content()
        let existing = try? String(contentsOf: url, encoding: .utf8)
        if check {
            if existing != content {
                outOfDate.append(output.path)
            }
        } else if existing != content {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try content.write(to: url, atomically: true, encoding: .utf8)
            print("wrote \(output.path)")
        } else {
            print("unchanged \(output.path)")
        }
    } catch {
        fail("swaylib-generate: \(output.path): \(error)")
    }
}

if !outOfDate.isEmpty {
    fail(
        "swaylib-generate: out of date, run `swift run swaylib-generate`:\n"
            + outOfDate.map { "  \($0)" }.joined(separator: "\n"))
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func raylibVersion(_ api: API) throws -> String {
    guard let define = api.defines.first(where: { $0.name == "RAYLIB_VERSION" }),
        case .string(let version) = define.value
    else {
        throw GenerateError("RAYLIB_VERSION define missing")
    }
    return version
}
