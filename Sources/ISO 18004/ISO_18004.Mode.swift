extension ISO_18004 {
    public enum Mode: Sendable, Hashable, CaseIterable {
        case numeric
        case alphanumeric
        case byte
    }
}

extension ISO_18004.Mode {
    static let alphanumerics: [UInt8] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:".utf8)

    public init(_ data: [UInt8]) {
        self = [Self.numeric, .alphanumeric].first { $0.holds(data) } ?? .byte
    }

    public func holds(_ data: [UInt8]) -> Bool {
        switch self {
        case .numeric: data.allSatisfy { (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) }

        case .alphanumeric: data.allSatisfy { Self.alphanumerics.contains($0) }

        case .byte: true
        }
    }

    var indicator: Int {
        switch self {
        case .numeric: 0b0001
        case .alphanumeric: 0b0010
        case .byte: 0b0100
        }
    }

    func count(_ version: ISO_18004.Version) -> Int {
        let range = version.number < 10 ? 0 : version.number < 27 ? 1 : 2
        switch self {
        case .numeric: return [10, 12, 14][range]

        case .alphanumeric: return [9, 11, 13][range]

        case .byte: return [8, 16, 16][range]
        }
    }

    func characters(_ bits: Int) -> Int {
        switch self {
        case .numeric: 3 * (bits / 10) + (bits % 10 >= 7 ? 2 : bits % 10 >= 4 ? 1 : 0)
        case .alphanumeric: 2 * (bits / 11) + (bits % 11 >= 6 ? 1 : 0)
        case .byte: bits / 8
        }
    }

    func groups(_ data: [UInt8]) -> [(value: Int, width: Int)] {
        switch self {
        case .numeric:
            return stride(from: 0, to: data.count, by: 3).map { start in
                let digits = data[start..<min(start + 3, data.count)]
                let value = digits.reduce(0) { $0 * 10 + Int($1 - UInt8(ascii: "0")) }
                return (value, [0, 4, 7, 10][digits.count])
            }

        case .alphanumeric:
            let values = data.compactMap { Self.alphanumerics.firstIndex(of: $0) }
            return stride(from: 0, to: values.count, by: 2).map { start in
                start + 1 < values.count ? (values[start] * 45 + values[start + 1], 11) : (values[start], 6)
            }

        case .byte:
            return data.map { (Int($0), 8) }
        }
    }
}
