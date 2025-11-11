module tipping::system_queries {
    use std::option::{Self, Option};

    use tipping::types::{Self, Tip, TippingSystem};

    // ============ System Query Functions ============

    /// Returns the total number of tips processed
    public fun total_tips(system: &TippingSystem): u64 {
        types::total_tips(system)
    }

    /// Returns the total volume of tips in MIST
    public fun total_volume(system: &TippingSystem): u64 {
        types::total_volume(system)
    }

    /// Returns the number of tips in history
    public fun history_size(system: &TippingSystem): u64 {
        types::history_size(system)
    }

    /// Returns a tip from history by index
    public fun get_tip(system: &TippingSystem, index: u64): Option<Tip> {
        let (exists, tip) = types::get_tip(system, index);
        if (exists) {
            option::some(tip)
        } else {
            option::none()
        }
    }

    /// Looks up an address by twitter handle (returns None if missing)
    public fun get_address_by_handle(system: &TippingSystem, handle: vector<u8>): Option<address> {
        let (exists, addr) = types::find_profile_address(system, handle);
        if (exists) {
            option::some(addr)
        } else {
            option::none()
        }
    }

    // ============ Helper Functions ============

    /// Converts MIST to SUI (for display)
    public fun mist_to_sui(mist: u64): u64 {
        mist / 1_000_000_000
    }
}
