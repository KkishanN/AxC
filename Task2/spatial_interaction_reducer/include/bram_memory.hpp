#ifndef BRAM_MEMORY_HPP
#define BRAM_MEMORY_HPP

#include "ic32.hpp"
#include <vector>
#include <queue>
#include <cstdint>
#include <stdexcept>

namespace spatial {

// Models on-chip BRAM / URAM banks for FPGA spatial reducer
class BramMemorySystem {
public:
    static constexpr size_t NUM_BANKS = 8;
    static constexpr size_t WORDS_PER_BANK = 65536; // 64K nodes per bank = 512K total nodes

    struct BankStats {
        uint64_t reads = 0;
        uint64_t writes = 0;
        uint64_t bank_conflicts = 0;
    };

private:
    std::vector<ic32::Node> banks[NUM_BANKS];
    std::queue<ic32::Addr> free_list;
    BankStats stats[NUM_BANKS];
    uint32_t allocated_high_water_mark = 0;
    uint32_t access_mask_current_cycle = 0;

public:
    BramMemorySystem() {
        for (size_t b = 0; b < NUM_BANKS; ++b) {
            banks[b].resize(WORDS_PER_BANK, {0, 0});
        }
        // Initialize free list
        allocated_high_water_mark = 1; // 0 reserved for null / root
    }

    // Interleaved address mapping: bank = addr % NUM_BANKS, offset = addr / NUM_BANKS
    inline size_t get_bank_index(ic32::Addr addr) const {
        return addr % NUM_BANKS;
    }

    inline size_t get_bank_offset(ic32::Addr addr) const {
        return addr / NUM_BANKS;
    }

    // Allocate a node from the hardware free list or high-water mark
    ic32::Addr allocate_node() {
        if (!free_list.empty()) {
            ic32::Addr recycled = free_list.front();
            free_list.pop();
            return recycled;
        }
        if (allocated_high_water_mark >= NUM_BANKS * WORDS_PER_BANK) {
            throw std::runtime_error("BRAM Memory Overflow: Max node capacity exceeded");
        }
        return allocated_high_water_mark++;
    }

    // Free a node to on-chip free-list
    void free_node(ic32::Addr addr) {
        if (addr != 0) {
            free_list.push(addr);
        }
    }

    // Simulates a hardware clock tick and resets cycle conflict masks
    void tick_cycle() {
        access_mask_current_cycle = 0;
    }

    // Read a node with bank conflict tracking
    ic32::Node read(ic32::Addr addr) {
        size_t b = get_bank_index(addr);
        size_t off = get_bank_offset(addr);

        stats[b].reads++;
        if ((access_mask_current_cycle & (1u << b)) != 0) {
            stats[b].bank_conflicts++; // Multiple accesses to same bank in single cycle
        }
        access_mask_current_cycle |= (1u << b);

        return banks[b][off];
    }

    // Write a node with bank conflict tracking
    void write(ic32::Addr addr, ic32::Node node) {
        size_t b = get_bank_index(addr);
        size_t off = get_bank_offset(addr);

        stats[b].writes++;
        if ((access_mask_current_cycle & (1u << b)) != 0) {
            stats[b].bank_conflicts++;
        }
        access_mask_current_cycle |= (1u << b);

        banks[b][off] = node;
    }

    // Get aggregate statistics
    uint64_t total_reads() const {
        uint64_t t = 0;
        for (const auto& s : stats) t += s.reads;
        return t;
    }

    uint64_t total_writes() const {
        uint64_t t = 0;
        for (const auto& s : stats) t += s.writes;
        return t;
    }

    uint64_t total_conflicts() const {
        uint64_t t = 0;
        for (const auto& s : stats) t += s.bank_conflicts;
        return t;
    }

    uint32_t active_nodes() const {
        return allocated_high_water_mark - static_cast<uint32_t>(free_list.size());
    }

    uint32_t peak_nodes() const {
        return allocated_high_water_mark;
    }
};

} // namespace spatial

#endif // BRAM_MEMORY_HPP
