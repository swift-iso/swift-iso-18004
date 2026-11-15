extension ISO_18004.Symbol {
    static func codewords(
        _ data: [UInt8],
        mode: ISO_18004.Mode,
        level: ISO_18004.Correction.Level,
        version: ISO_18004.Version
    ) -> [UInt8] {
        let capacity = version.data(level) * 8
        var bits: [Bool] = []
        func append(_ value: Int, _ count: Int) {
            for shift in stride(from: count - 1, through: 0, by: -1) {
                bits.append((value >> shift) & 1 == 1)
            }
        }
        append(mode.indicator, 4)
        append(data.count, mode.count(version))
        for group in mode.groups(data) { append(group.value, group.width) }
        append(0, min(4, capacity - bits.count))
        append(0, (8 - bits.count % 8) % 8)
        var pad = 0xEC
        while bits.count < capacity {
            append(pad, 8)
            pad = pad == 0xEC ? 0x11 : 0xEC
        }
        return stride(from: 0, to: bits.count, by: 8).map { start in
            bits[start..<start + 8].reduce(0) { $0 << 1 | ($1 ? 1 : 0) }
        }
    }

    static func interleaved(
        _ data: [UInt8],
        level: ISO_18004.Correction.Level,
        version: ISO_18004.Version
    ) -> [UInt8] {
        let count = level.blocks[version.number - 1]
        let length = level.correction[version.number - 1]
        let total = version.codewords
        let short = count - total % count
        let shortLength = total / count
        let divisor = Self.divisor(length)
        var parts: [[UInt8]] = []
        var start = 0
        for index in 0..<count {
            let size = shortLength - length + (index < short ? 0 : 1)
            var part = Array(data[start..<start + size])
            start += size
            let remainder = Self.remainder(part, divisor)
            if index < short { part.append(0) }
            parts.append(part + remainder)
        }
        var result: [UInt8] = []
        for position in 0...shortLength {
            for (index, part) in parts.enumerated() where position != shortLength - length || index >= short {
                result.append(part[position])
            }
        }
        return result
    }

    static func product(_ x: UInt8, _ y: UInt8) -> UInt8 {
        var z = 0
        for shift in stride(from: 7, through: 0, by: -1) {
            z = (z << 1) ^ ((z >> 7) * 0x11D)
            z ^= ((Int(y) >> shift) & 1) * Int(x)
        }
        return UInt8(truncatingIfNeeded: z)
    }

    static func divisor(_ degree: Int) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: degree - 1) + [1]
        var root: UInt8 = 1
        for _ in 0..<degree {
            for index in 0..<degree {
                result[index] = product(result[index], root)
                if index + 1 < degree { result[index] ^= result[index + 1] }
            }
            root = product(root, 2)
        }
        return result
    }

    static func remainder(_ data: [UInt8], _ divisor: [UInt8]) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: divisor.count)
        for byte in data {
            let factor = byte ^ result.removeFirst()
            result.append(0)
            for index in result.indices { result[index] ^= product(divisor[index], factor) }
        }
        return result
    }
}
