import Foundation

// The shape of raylib's tools/rlparser/output/raylib_api.json. Only the parts the generator reads.

struct API: Decodable {
    var defines: [Define]
    var structs: [Struct]
    var enums: [Enum]
    var functions: [Function]

    struct Define: Decodable {
        var name: String
        var type: String
        var value: Value
        var description: String

        enum Value: Decodable {
            case string(String)
            case number(Double)

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let number = try? container.decode(Double.self) {
                    self = .number(number)
                } else {
                    self = .string(try container.decode(String.self))
                }
            }
        }
    }

    struct Struct: Decodable {
        var name: String
        var description: String
        var fields: [Field]

        struct Field: Decodable {
            var type: String
            var name: String
            var description: String
        }
    }

    struct Enum: Decodable {
        var name: String
        var description: String
        var values: [Value]

        struct Value: Decodable {
            var name: String
            var value: Int
            var description: String
        }
    }

    struct Function: Decodable {
        var name: String
        var description: String
        var returnType: String
        var params: [Param]?

        struct Param: Decodable {
            var type: String
            var name: String
        }

        var signature: String {
            let parameters = (params ?? []).map { "\($0.type) \($0.name)" }.joined(separator: ", ")
            return "\(returnType) \(name)(\(parameters))"
        }
    }

    static func load(from url: URL) throws -> API {
        try JSONDecoder().decode(API.self, from: Data(contentsOf: url))
    }
}

/// raylib's enums that are bit flags rather than one-of values.
let optionSetEnums: Set<String> = ["ConfigFlags", "Gesture"]

/// The first function of each raylib module, in header order, used to split the coverage table.
let moduleStarts: [(module: String, firstFunction: String)] = [
    ("rcore", "InitWindow"),
    ("rshapes", "SetShapesTexture"),
    ("rtextures", "LoadImage"),
    ("rtext", "GetFontDefault"),
    ("rmodels", "DrawLine3D"),
    ("raudio", "InitAudioDevice"),
]
