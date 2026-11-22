# swift-iso-18004

Use this package when you need to make a QR Code symbol (ISO/IEC 18004:2015) from bytes: `` ISO.`18004`.Symbol(data, level:) `` returns the grid of dark and light modules, or nil when no symbol holds the data. Drawing it (an image, SVG path data, a terminal) is the caller's: read `symbol.modules[y][x]`, row by row, for each of the `size` × `size` modules and leave a quiet zone of `` ISO.`18004`.Symbol.quiet `` light modules on every side, `extent` modules across in all.

## Coverage

- Encoding only. Reading a symbol back from an image is not covered.
- QR Code model 2, versions 1 to 40 (`` ISO.`18004`.Version ``), at all four error correction levels L, M, Q and H (`` ISO.`18004`.Correction.Level `` `.low`, `.medium`, `.quartile`, `.high`).
- Numeric, alphanumeric and byte mode (`` ISO.`18004`.Mode ``), one mode per symbol. Kanji mode, ECI, FNC1, Structured Append, mixed-mode segments, Micro QR and rMQR are not covered.
- All eight data mask patterns (`` ISO.`18004`.Mask ``).

## Laws

- Without a mode, a symbol uses the most compact mode that holds every byte: numeric for digits only, alphanumeric for the 45 characters `0`–`9`, `A`–`Z`, space and `$%*+-./:`, byte otherwise. A mode that does not hold the data gives nil.
- Without a version, a symbol takes the smallest version whose capacity at that mode and level holds the data. A version smaller than that gives nil. `` ISO.`18004`.Version.capacity(_:_:) `` is the standard's capacity table, in characters.
- Without a mask, a symbol takes the pattern with the lowest penalty score of section 7.8.3; ties go to the lower reference.
- Byte mode writes the bytes as given. The standard's default reading is ISO/IEC 8859-1; most readers take UTF-8, so text is passed as its UTF-8 bytes.
- The annex example, `01234567` at version 1-M, gives the standard's data and error correction codewords, and the capacities of versions 1 and 40 equal the standard's table. On Apple platforms the tests read symbols of every level, mode and mask back with the system's own QR reader.
