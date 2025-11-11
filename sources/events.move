module tipping::events {
    use std::string::String;
    use sui::event;

    /// Event emitted when a tip is sent
    public struct TipSent has copy, drop {
        from: address,
        to: address,
        amount: u64,
        message: String,
    }

    /// Event emitted when a profile is created
    public struct ProfileCreated has copy, drop {
        address: address,
        name: String,
    }

    // ============ Emission Functions ============

    public fun emit_tip_sent(
        from: address,
        to: address,
        amount: u64,
        message: String
    ) {
        event::emit(TipSent {
            from,
            to,
            amount,
            message,
        });
    }

    public fun emit_profile_created(
        address: address,
        name: String
    ) {
        event::emit(ProfileCreated {
            address,
            name,
        });
    }
}
