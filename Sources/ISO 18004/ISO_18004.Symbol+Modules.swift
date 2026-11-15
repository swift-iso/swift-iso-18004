extension ISO_18004.Symbol {
    static func alignments(_ version: ISO_18004.Version) -> [Int] {
        let number = version.number
        guard number > 1 else { return [] }
        let count = number / 7 + 2
        let step = number == 32 ? 26 : (number * 4 + count * 2 + 1) / (count * 2 - 2) * 2
        var result = [6]
        var position = version.size - 7
        var rest: [Int] = []
        while rest.count < count - 1 {
            rest.append(position)
            position -= step
        }
        result += rest.reversed()
        return result
    }

    static func drawn(_ codewords: [UInt8], version: ISO_18004.Version) -> (dark: [Bool], reserved: [Bool]) {
        let size = version.size
        var dark = [Bool](repeating: false, count: size * size)
        var reserved = [Bool](repeating: false, count: size * size)
        func set(_ x: Int, _ y: Int, _ value: Bool) {
            dark[y * size + x] = value
            reserved[y * size + x] = true
        }
        for index in 0..<size {
            set(6, index, index % 2 == 0)
            set(index, 6, index % 2 == 0)
        }
        for (centerX, centerY) in [(3, 3), (size - 4, 3), (3, size - 4)] {
            for dy in -4...4 {
                for dx in -4...4 {
                    let x = centerX + dx
                    let y = centerY + dy
                    guard (0..<size).contains(x), (0..<size).contains(y) else { continue }
                    let distance = max(abs(dx), abs(dy))
                    set(x, y, distance != 2 && distance != 4)
                }
            }
        }
        let positions = alignments(version)
        let last = positions.count - 1
        for (row, centerY) in positions.enumerated() {
            for (column, centerX) in positions.enumerated() {
                if (row == 0 && column == 0) || (row == 0 && column == last) || (row == last && column == 0) { continue }
                for dy in -2...2 {
                    for dx in -2...2 {
                        set(centerX + dx, centerY + dy, max(abs(dx), abs(dy)) != 1)
                    }
                }
            }
        }
        for index in 0..<9 {
            if index != 6 {
                set(8, index, false)
                set(index, 8, false)
            }
        }
        for index in 0..<8 {
            set(size - 1 - index, 8, false)
            set(8, size - 1 - index, false)
        }
        set(8, size - 8, true)
        if version.number >= 7 {
            var remainder = version.number
            for _ in 0..<12 { remainder = (remainder << 1) ^ ((remainder >> 11) * 0x1F25) }
            let bits = version.number << 12 | remainder
            for index in 0..<18 {
                let bit = (bits >> index) & 1 == 1
                let a = size - 11 + index % 3
                let b = index / 3
                set(a, b, bit)
                set(b, a, bit)
            }
        }
        var index = 0
        var right = size - 1
        while right >= 1 {
            if right == 6 { right = 5 }
            for vertical in 0..<size {
                for offset in 0..<2 {
                    let x = right - offset
                    let upward = (right + 1) & 2 == 0
                    let y = upward ? size - 1 - vertical : vertical
                    guard !reserved[y * size + x], index < codewords.count * 8 else { continue }
                    dark[y * size + x] = (codewords[index >> 3] >> (7 - UInt8(index & 7))) & 1 == 1
                    index += 1
                }
            }
            right -= 2
        }
        return (dark, reserved)
    }

    static func masked(
        _ dark: [Bool],
        reserved: [Bool],
        version: ISO_18004.Version,
        level: ISO_18004.Correction.Level,
        mask: ISO_18004.Mask
    ) -> [Bool] {
        let size = version.size
        var result = dark
        for y in 0..<size {
            for x in 0..<size where !reserved[y * size + x] && mask.inverts(row: y, column: x) {
                result[y * size + x].toggle()
            }
        }
        let format = level.indicator << 3 | mask.reference
        var remainder = format
        for _ in 0..<10 { remainder = (remainder << 1) ^ ((remainder >> 9) * 0x537) }
        let bits = (format << 10 | remainder) ^ 0x5412
        func bit(_ index: Int) -> Bool { (bits >> index) & 1 == 1 }
        func set(_ x: Int, _ y: Int, _ value: Bool) { result[y * size + x] = value }
        for index in 0...5 { set(8, index, bit(index)) }
        set(8, 7, bit(6))
        set(8, 8, bit(7))
        set(7, 8, bit(8))
        for index in 9..<15 { set(14 - index, 8, bit(index)) }
        for index in 0..<8 { set(size - 1 - index, 8, bit(index)) }
        for index in 8..<15 { set(8, size - 15 + index, bit(index)) }
        return result
    }

    static func penalty(_ modules: [Bool], size: Int) -> Int {
        var result = 0
        let finder: [[Bool]] = [
            [true, false, true, true, true, false, true, false, false, false, false],
            [false, false, false, false, true, false, true, true, true, false, true],
        ]
        for transposed in [false, true] {
            for line in 0..<size {
                let cells = (0..<size).map { transposed ? modules[$0 * size + line] : modules[line * size + $0] }
                var run = 1
                for index in 1..<size {
                    if cells[index] == cells[index - 1] {
                        run += 1
                        if run == 5 { result += 3 } else if run > 5 { result += 1 }
                    } else {
                        run = 1
                    }
                }
                if size >= 11 {
                    for start in 0...(size - 11) where finder.contains(Array(cells[start..<start + 11])) {
                        result += 40
                    }
                }
            }
        }
        for y in 0..<size - 1 {
            for x in 0..<size - 1 {
                let colour = modules[y * size + x]
                if colour == modules[y * size + x + 1], colour == modules[(y + 1) * size + x], colour == modules[(y + 1) * size + x + 1] {
                    result += 3
                }
            }
        }
        let total = size * size
        let darkCount = modules.count(where: \.self)
        result += ((abs(darkCount * 20 - total * 10) + total - 1) / total - 1) * 10
        return result
    }
}
