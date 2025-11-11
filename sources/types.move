module tipping::types {
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use std::string::{Self, String};
    use std::vector;

    use tipping::errors;

    /// User profile in the tipping system
    public struct UserProfile has key, store {
        id: UID,
        address: address,
        name: String,
        bio: String,
        twitter_handle: String,
        total_received: u64,        // Total SUI received in tips (in MIST)
        total_sent: u64,            // Total SUI sent in tips (in MIST)
        tips_received_count: u64,
        tips_sent_count: u64,
    }

    /// Individual tip record
    public struct Tip has store, copy, drop {
        from: address,               // Address of sender
        to: address,                 // Address of receiver
        amount: u64,                 // Amount in MIST (1 SUI = 1_000_000_000 MIST)
        message: String,             // Optional message
        timestamp: u64,              // Transaction timestamp
    }

    /// Main tipping system (shared object)
    public struct TippingSystem has key {
        id: UID,
        total_tips: u64,             // Total tips processed
        total_volume: u64,           // Total volume in MIST
        history: vector<Tip>,        // History of all tips
        twitter_registry: Table<vector<u8>, address>, // twitter handle -> address lookup
        address_registry: Table<address, vector<u8>>, // wallet -> handle lookup
    }

    // ============ Creation Functions ============

    public fun create_profile(
        address: address,
        name: String,
        bio: String,
        twitter_handle: String,
        ctx: &mut TxContext
    ): UserProfile {
        UserProfile {
            id: object::new(ctx),
            address,
            name,
            bio,
            twitter_handle,
            total_received: 0,
            total_sent: 0,
            tips_received_count: 0,
            tips_sent_count: 0,
        }
    }

    public fun create_system(ctx: &mut TxContext): TippingSystem {
        TippingSystem {
            id: object::new(ctx),
            total_tips: 0,
            total_volume: 0,
            history: vector::empty(),
            twitter_registry: table::new(ctx),
            address_registry: table::new(ctx),
        }
    }

    public fun create_tip(
        from: address,
        to: address,
        amount: u64,
        message: String,
        timestamp: u64
    ): Tip {
        Tip {
            from,
            to,
            amount,
            message,
            timestamp,
        }
    }

    // ============ Transfer Functions ============

    public fun transfer_profile(profile: UserProfile, address: address) {
        transfer::public_transfer(profile, address);
    }

    public fun share_system(system: TippingSystem) {
        transfer::share_object(system);
    }


    // ============ Access Functions ============

    public fun profile_address(profile: &UserProfile): address {
        profile.address
    }

    public fun profile_name(profile: &UserProfile): String {
        copy profile.name
    }

    public fun profile_bio(profile: &UserProfile): String {
        copy profile.bio
    }

    public fun profile_twitter_handle(profile: &UserProfile): String {
        copy profile.twitter_handle
    }

    public fun total_received(profile: &UserProfile): u64 {
        profile.total_received
    }

    public fun total_sent(profile: &UserProfile): u64 {
        profile.total_sent
    }

    public fun tips_received_count(profile: &UserProfile): u64 {
        profile.tips_received_count
    }

    public fun tips_sent_count(profile: &UserProfile): u64 {
        profile.tips_sent_count
    }

    // ============ Modification Functions ============

    public fun set_profile_name(profile: &mut UserProfile, name: String) {
        profile.name = name;
    }

    public fun set_profile_bio(profile: &mut UserProfile, bio: String) {
        profile.bio = bio;
    }

    public fun set_profile_twitter(profile: &mut UserProfile, twitter: String) {
        profile.twitter_handle = twitter;
    }

    public fun increment_total_received(profile: &mut UserProfile, amount: u64) {
        profile.total_received = profile.total_received + amount;
    }

    public fun increment_total_sent(profile: &mut UserProfile, amount: u64) {
        profile.total_sent = profile.total_sent + amount;
    }

    public fun increment_tips_received(profile: &mut UserProfile) {
        profile.tips_received_count = profile.tips_received_count + 1;
    }

    public fun increment_tips_sent(profile: &mut UserProfile) {
        profile.tips_sent_count = profile.tips_sent_count + 1;
    }

    public fun add_tip_to_history(system: &mut TippingSystem, tip: Tip) {
        vector::push_back(&mut system.history, tip);
    }

    public fun increment_total_tips(system: &mut TippingSystem) {
        system.total_tips = system.total_tips + 1;
    }

    public fun increment_total_volume(system: &mut TippingSystem, amount: u64) {
        system.total_volume = system.total_volume + amount;
    }

    public fun total_tips(system: &TippingSystem): u64 {
        system.total_tips
    }

    public fun total_volume(system: &TippingSystem): u64 {
        system.total_volume
    }

    public fun history_size(system: &TippingSystem): u64 {
        vector::length(&system.history)
    }

    public fun get_tip(system: &TippingSystem, index: u64): (bool, Tip) {
        let size = vector::length(&system.history);
        if (index >= size) {
            let tip = create_tip(@0x0, @0x0, 0, string::utf8(b""), 0);
            return (false, tip)
        };
        let tip_ref = vector::borrow(&system.history, index);
        (true, *tip_ref)
    }

    // ============ Twitter Handle Registry ============

    public fun register_profile(
        system: &mut TippingSystem,
        handle: vector<u8>,
        owner: address
    ) {
        assert!(vector::length(&handle) > 0, errors::invalid_handle());
        let lookup_key = clone_bytes(&handle);
        assert!(!table::contains(&system.twitter_registry, lookup_key), errors::handle_taken());
        table::add(&mut system.twitter_registry, handle, owner);
    }

    public fun register_owner(
        system: &mut TippingSystem,
        owner: address,
        handle: vector<u8>
    ) {
        assert!(!table::contains(&system.address_registry, owner), errors::profile_already_exists());
        table::add(&mut system.address_registry, owner, handle);
    }

    public fun owner_has_profile(system: &TippingSystem, owner: address): bool {
        table::contains(&system.address_registry, owner)
    }

    public fun find_profile_address(
        system: &TippingSystem,
        handle: vector<u8>
    ): (bool, address) {
        let lookup_key = clone_bytes(&handle);
        if (!table::contains(&system.twitter_registry, lookup_key)) {
            (false, @0x0)
        } else {
            let addr_ref = table::borrow(&system.twitter_registry, handle);
            (true, *addr_ref)
        }
    }

    public fun profiles_count(system: &TippingSystem): u64 {
        table::length(&system.twitter_registry)
    }

    public fun owner_handle(system: &TippingSystem, owner: address): vector<u8> {
        let handle_ref = table::borrow(&system.address_registry, owner);
        clone_bytes(handle_ref)
    }

    public fun remove_owner(system: &mut TippingSystem, owner: address) {
        table::remove(&mut system.address_registry, owner);
    }

    public fun remove_handle_entry(system: &mut TippingSystem, handle: vector<u8>) {
        table::remove(&mut system.twitter_registry, handle);
    }

    public fun handle_exists(system: &TippingSystem, handle: &vector<u8>): bool {
        let lookup = clone_bytes(handle);
        table::contains(&system.twitter_registry, lookup)
    }

    public fun clone_bytes(data: &vector<u8>): vector<u8> {
        let mut out = vector::empty<u8>();
        let len = vector::length(data);
        let mut i = 0;
        while (i < len) {
            let byte = *vector::borrow(data, i);
            vector::push_back(&mut out, byte);
            i = i + 1;
        };
        out
    }
}
