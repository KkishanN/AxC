#ifndef IC32_HPP
#define IC32_HPP

#include <cstdint>
#include <string>

// IC32: 32-bit packed node encoding for Interaction Calculus
// [sub: 1 bit][tag: 5 bits][val: 26 bits]
namespace ic32 {

enum Tag : uint8_t {
    TAG_VAR = 0x00, // Variable
    TAG_LAM = 0x01, // Lambda
    TAG_APP = 0x02, // Application
    TAG_ERA = 0x03, // Erasure
    TAG_NUM = 0x04, // Numeric constant
    TAG_SUC = 0x05, // Successor
    TAG_SWI = 0x06, // Switch
    TAG_SUP = 0x07, // Superposition &L{a, b}
    TAG_DUP = 0x08, // Duplication request !&L{x, y} = t
};

using Word = uint32_t;
using Addr = uint32_t;

inline Word pack(bool sub, Tag tag, uint32_t val) {
    return ((sub ? 1u : 0u) << 31) | ((static_cast<uint32_t>(tag) & 0x1Fu) << 26) | (val & 0x03FFFFFFu);
}

inline bool get_sub(Word w) {
    return (w >> 31) & 1;
}

inline Tag get_tag(Word w) {
    return static_cast<Tag>((w >> 26) & 0x1F);
}

inline uint32_t get_val(Word w) {
    return w & 0x03FFFFFFu;
}

inline const char* tag_to_string(Tag t) {
    switch (t) {
        case TAG_VAR: return "VAR";
        case TAG_LAM: return "LAM";
        case TAG_APP: return "APP";
        case TAG_ERA: return "ERA";
        case TAG_NUM: return "NUM";
        case TAG_SUC: return "SUC";
        case TAG_SWI: return "SWI";
        case TAG_SUP: return "SUP";
        case TAG_DUP: return "DUP";
        default:      return "UNKNOWN";
    }
}

// Node structure on heap / BRAM
// A binary node in Interaction Calculus contains two port pointers: port 0 (left/aux1) and port 1 (right/aux2)
struct Node {
    Word p0; // Port 0 (or principal port)
    Word p1; // Port 1 (auxiliary port)
};

} // namespace ic32

#endif // IC32_HPP
