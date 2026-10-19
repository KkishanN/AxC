#ifndef RULE_BLOCKS_HPP
#define RULE_BLOCKS_HPP

#include "ic32.hpp"
#include "bram_memory.hpp"
#include <vector>
#include <cstdint>

namespace spatial {

// Represents an active interaction pair (redex) in hardware
struct ActiveRedex {
    ic32::Addr addr_a;
    ic32::Tag tag_a;
    ic32::Addr addr_b;
    ic32::Tag tag_b;
};

// Hardware rewrite event metrics
struct RuleBlockMetrics {
    uint64_t app_lam_rewrites = 0;
    uint64_t app_sup_rewrites = 0;
    uint64_t dup_lam_rewrites = 0;
    uint64_t dup_sup_annihilations = 0;
    uint64_t dup_sup_commutations = 0;
    uint64_t era_rewrites = 0;
    uint64_t num_rewrites = 0;

    uint64_t total_interactions() const {
        return app_lam_rewrites + app_sup_rewrites + dup_lam_rewrites +
               dup_sup_annihilations + dup_sup_commutations + era_rewrites + num_rewrites;
    }
};

class RuleBlockExecutor {
public:
    // Dispatches and executes an active redex in hardware rule blocks
    // Returns any newly spawned active redexes
    static std::vector<ActiveRedex> execute_rule(
        const ActiveRedex& redex,
        BramMemorySystem& mem,
        RuleBlockMetrics& metrics
    ) {
        std::vector<ActiveRedex> spawned;
        ic32::Tag t_a = redex.tag_a;
        ic32::Tag t_b = redex.tag_b;
        ic32::Addr a = redex.addr_a;
        ic32::Addr b = redex.addr_b;

        // Ensure canonical ordering (e.g. APP before LAM, DUP before SUP)
        if (t_a > t_b) {
            std::swap(t_a, t_b);
            std::swap(a, b);
        }

        // 1. APP-LAM: Substitution ((λx. body) arg)
        if (t_a == ic32::TAG_LAM && t_b == ic32::TAG_APP) {
            metrics.app_lam_rewrites++;
            ic32::Node lam = mem.read(a);
            ic32::Node app = mem.read(b);

            // In Interaction Calculus, substitution is a direct wire swap:
            // x <- app.p1 (arg); body is connected to app.p0
            // Re-wire ports:
            ic32::Word arg = app.p1;
            ic32::Word body = lam.p1;

            mem.free_node(a);
            mem.free_node(b);

            if (ic32::get_tag(body) == ic32::TAG_VAR) {
                // Resolved variable binding
            } else if (ic32::get_tag(body) == ic32::TAG_APP) {
                spawned.push_back({ic32::get_val(body), ic32::TAG_APP, ic32::get_val(arg), ic32::get_tag(arg)});
            }
        }
        // 2. DUP-SUP: Annihilation (equal labels) or Commutation (different labels)
        else if (t_a == ic32::TAG_SUP && t_b == ic32::TAG_DUP) {
            ic32::Node sup = mem.read(a);
            ic32::Node dup = mem.read(b);

            uint32_t label_sup = ic32::get_val(sup.p0);
            uint32_t label_dup = ic32::get_val(dup.p0);

            if (label_sup == label_dup) {
                // Annihilation: !&L{x, y} = &L{a, b} => x <- a, y <- b
                metrics.dup_sup_annihilations++;
                mem.free_node(a);
                mem.free_node(b);
            } else {
                // Commutation: labels differ => commute into duplicate superpositions
                metrics.dup_sup_commutations++;
                ic32::Addr s0 = mem.allocate_node();
                ic32::Addr s1 = mem.allocate_node();

                mem.write(s0, {sup.p0, dup.p1});
                mem.write(s1, {sup.p1, dup.p1});

                mem.free_node(a);
                mem.free_node(b);
            }
        }
        // 3. APP-SUP: Application distributes into Superposition branches
        else if (t_a == ic32::TAG_APP && t_b == ic32::TAG_SUP) {
            metrics.app_sup_rewrites++;
            ic32::Node app = mem.read(a);
            ic32::Node sup = mem.read(b);

            ic32::Addr a0 = mem.allocate_node();
            ic32::Addr a1 = mem.allocate_node();

            mem.write(a0, {sup.p0, app.p1});
            mem.write(a1, {sup.p1, app.p1});

            mem.free_node(a);
            mem.free_node(b);
        }
        // 4. DUP-LAM: Duplication copies a Lambda
        else if (t_a == ic32::TAG_LAM && t_b == ic32::TAG_DUP) {
            metrics.dup_lam_rewrites++;
            ic32::Node lam = mem.read(a);
            ic32::Node dup = mem.read(b);

            ic32::Addr l0 = mem.allocate_node();
            ic32::Addr l1 = mem.allocate_node();

            mem.write(l0, {lam.p0, dup.p0});
            mem.write(l1, {lam.p1, dup.p1});

            mem.free_node(a);
            mem.free_node(b);
        }
        // 5. ERA (Erasure): Term no longer referenced
        else if (t_a == ic32::TAG_ERA || t_b == ic32::TAG_ERA) {
            metrics.era_rewrites++;
            mem.free_node(a);
            mem.free_node(b);
        }
        // 6. NUM / SUC: Numeric evaluation
        else if (t_a == ic32::TAG_NUM && t_b == ic32::TAG_SUC) {
            metrics.num_rewrites++;
            ic32::Node num = mem.read(a);
            uint32_t val = ic32::get_val(num.p0) + 1;
            mem.write(a, {ic32::pack(false, ic32::TAG_NUM, val), 0});
            mem.free_node(b);
        }

        return spawned;
    }
};

} // namespace spatial

#endif // RULE_BLOCKS_HPP
