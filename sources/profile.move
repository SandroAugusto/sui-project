module tipping::profile {
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use std::vector;

    use tipping::types::{Self, UserProfile, TippingSystem};
    use tipping::events;
    use tipping::errors;

    // ============ Public Profile Functions ============

    /// Creates a user profile, registers it in the system, and links to a Twitter handle
    #[allow(lint(public_entry))]
    public entry fun create_profile_with_system(
        system: &mut TippingSystem,
        name: String,
        bio: String,
        twitter_handle: String,
        ctx: &mut TxContext
    ) {
        let address = tx_context::sender(ctx);
        let handle_bytes = string::into_bytes(copy twitter_handle);
        let owner_handle_bytes = types::clone_bytes(&handle_bytes);
        
        assert!(!types::owner_has_profile(system, address), errors::profile_already_exists());

        let profile = types::create_profile(
            address,
            name,
            bio,
            twitter_handle,
            ctx
        );

        let profile_name = types::profile_name(&profile);
        types::register_owner(system, address, owner_handle_bytes);
        types::register_profile(system, handle_bytes, address);
        types::transfer_profile(profile, address);
        events::emit_profile_created(address, profile_name);
    }

    /// Legacy profile creation (used in tests) - does not register twitter handle
    #[test_only]
    #[allow(lint(public_entry))]
    public entry fun create_profile(
        name: vector<u8>,
        ctx: &mut TxContext
    ) {
        let address = tx_context::sender(ctx);
        let name_string = string::utf8(name);
        let profile = types::create_profile(
            address,
            copy name_string,
            string::utf8(b""),
            string::utf8(b""),
            ctx
        );

        types::transfer_profile(profile, address);
        events::emit_profile_created(address, name_string);
    }

    // ============ Profile Query Functions ============

    /// Returns complete statistics for a profile
    public fun profile_statistics(profile: &UserProfile): (address, String, u64, u64, u64, u64) {
        (
            types::profile_address(profile),
            types::profile_name(profile),
            types::total_received(profile),
            types::total_sent(profile),
            types::tips_received_count(profile),
            types::tips_sent_count(profile),
        )
    }

    /// Returns the name of a profile
    public fun profile_name(profile: &UserProfile): String {
        types::profile_name(profile)
    }

    /// Returns the address of a profile
    public fun profile_address(profile: &UserProfile): address {
        types::profile_address(profile)
    }

    /// Returns the total received by a profile
    public fun profile_total_received(profile: &UserProfile): u64 {
        types::total_received(profile)
    }

    /// Returns the total sent by a profile
    public fun profile_total_sent(profile: &UserProfile): u64 {
        types::total_sent(profile)
    }

    // ============ Profile Update Functions ============

    #[allow(lint(public_entry))]
    public entry fun update_bio(
        profile: &mut UserProfile,
        bio: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == types::profile_address(profile), errors::profile_not_exists());
        let bio_string = string::utf8(bio);
        types::set_profile_bio(profile, bio_string);
    }

    #[allow(lint(public_entry))]
    public entry fun update_twitter(
        system: &mut TippingSystem,
        profile: &mut UserProfile,
        twitter_handle: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == types::profile_address(profile), errors::profile_not_exists());

        assert!(vector::length(&twitter_handle) > 0, errors::invalid_handle());
        let registry_bytes = types::clone_bytes(&twitter_handle);
        assert!(!types::handle_exists(system, &registry_bytes), errors::handle_taken());

        let current_handle = types::owner_handle(system, sender);
        types::remove_handle_entry(system, types::clone_bytes(&current_handle));
        types::remove_owner(system, sender);

        let owner_bytes = types::clone_bytes(&twitter_handle);
        let profile_bytes = types::clone_bytes(&twitter_handle);
        types::register_owner(system, sender, owner_bytes);
        types::register_profile(system, registry_bytes, sender);

        let handle_string = string::utf8(twitter_handle);
        let mut name_bytes = vector::empty<u8>();
        vector::push_back(&mut name_bytes, 64); // '@'
        vector::append(&mut name_bytes, types::clone_bytes(&profile_bytes));
        let display_name = string::utf8(name_bytes);

        types::set_profile_twitter(profile, handle_string);
        types::set_profile_name(profile, display_name);
    }
}
