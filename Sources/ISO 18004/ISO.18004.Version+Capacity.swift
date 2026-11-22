extension ISO.`18004`.Version {
    var modules: Int {
        var result = (16 * number + 128) * number + 64
        if number >= 2 {
            let alignments = number / 7 + 2
            result -= (25 * alignments - 10) * alignments - 55
            if number >= 7 { result -= 36 }
        }
        return result
    }

    var codewords: Int { modules / 8 }

    func data(_ level: ISO.`18004`.Correction.Level) -> Int {
        codewords - level.correction[number - 1] * level.blocks[number - 1]
    }

    public func capacity(_ mode: ISO.`18004`.Mode, _ level: ISO.`18004`.Correction.Level) -> Int {
        mode.characters(data(level) * 8 - 4 - mode.count(self))
    }
}
