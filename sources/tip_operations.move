module tipping::tip_operations {
    use sui::coin::{Coin, Self};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    use std::string::Self;

    use tipping::types::{Self, UserProfile, Tip, TippingSystem};
    use tipping::events;
    use tipping::errors;

    // ============ Public Tip Functions ============

    /// Sends a tip to another user providing both profiles (used in tests)
    #[allow(lint(public_entry))]
    public entry fun send_tip(
        system: &mut TippingSystem,
        sender_profile: &mut UserProfile,
        receiver_profile: &mut UserProfile,
        coin: Coin<SUI>,
        message: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let receiver = types::profile_address(receiver_profile);
        let amount = coin::value(&coin);
        let message_string = string::utf8(message);
        let timestamp = tx_context::epoch_timestamp_ms(ctx);

        // Validations
        validate_tip(sender, sender_profile, receiver_profile, amount);

        // Create and register the tip
        let tip = types::create_tip(
            sender,
            receiver,
            amount,
            message_string,
            timestamp
        );

        // Update statistics
        update_statistics(system, sender_profile, receiver_profile, tip, amount);

        // Transfer coin to receiver
        sui::transfer::public_transfer(coin, receiver);

        // Emit event
        events::emit_tip_sent(
            sender,
            receiver,
            amount,
            message_string
        );
    }

    /// Sends a tip when only the sender profile is available (production flow)
    #[allow(lint(public_entry))]
    public entry fun send_tip_with_profile_address(
        system: &mut TippingSystem,
        sender_profile: &mut UserProfile,
        receiver: address,
        coin: Coin<SUI>,
        message: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let amount = coin::value(&coin);
        let message_string = string::utf8(message);
        let timestamp = tx_context::epoch_timestamp_ms(ctx);

        assert!(amount > 0, errors::invalid_value());
        assert!(sender == types::profile_address(sender_profile), errors::profile_not_exists());
        assert!(sender != receiver, errors::same_user());

        let tip = types::create_tip(
            sender,
            receiver,
            amount,
            message_string,
            timestamp
        );

        // Update system statistics
        types::add_tip_to_history(system, tip);
        types::increment_total_tips(system);
        types::increment_total_volume(system, amount);

        // Update sender profile statistics
        types::increment_total_sent(sender_profile, amount);
        types::increment_tips_sent(sender_profile);

        // Transfer coin and emit
        sui::transfer::public_transfer(coin, receiver);
        events::emit_tip_sent(sender, receiver, amount, message_string);
    }

    /// Sends a tip without requiring sender profile (for users without profile)
    #[allow(lint(public_entry))]
    public entry fun send_tip_no_profile(
        system: &mut TippingSystem,
        receiver: address,
        coin: Coin<SUI>,
        message: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let amount = coin::value(&coin);
        let message_string = string::utf8(message);
        let timestamp = tx_context::epoch_timestamp_ms(ctx);

        // Validations
        assert!(amount > 0, errors::invalid_value());
        assert!(sender != receiver, errors::same_user());

        let tip = types::create_tip(
            sender,
            receiver,
            amount,
            message_string,
            timestamp
        );

        types::add_tip_to_history(system, tip);
        types::increment_total_tips(system);
        types::increment_total_volume(system, amount);

        sui::transfer::public_transfer(coin, receiver);
        events::emit_tip_sent(sender, receiver, amount, message_string);
    }

    // ============ Receiver Statistics Update ============

    /// Allows a receiver to update their statistics after receiving a tip
    /// Useful when the receiver profile wasn't available during the tip
    #[allow(lint(public_entry))]
    public entry fun update_receiver_stats(
        receiver_profile: &mut UserProfile,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let receiver = tx_context::sender(ctx);
        assert!(receiver == types::profile_address(receiver_profile), errors::profile_not_exists());
        
        types::increment_total_received(receiver_profile, amount);
        types::increment_tips_received(receiver_profile);
    }

    // ============ Private Helpers ============

    fun validate_tip(
        sender: address,
        sender_profile: &UserProfile,
        receiver_profile: &UserProfile,
        amount: u64
    ) {
        let sender_address = types::profile_address(sender_profile);
        let receiver_address = types::profile_address(receiver_profile);
        assert!(amount > 0, errors::invalid_value());
        assert!(sender == sender_address, errors::profile_not_exists());
        assert!(sender_address != receiver_address, errors::same_user());
    }

    fun update_statistics(
        system: &mut TippingSystem,
        sender_profile: &mut UserProfile,
        receiver_profile: &mut UserProfile,
        tip: Tip,
        amount: u64
    ) {
        types::add_tip_to_history(system, tip);
        types::increment_total_tips(system);
        types::increment_total_volume(system, amount);

        types::increment_total_sent(sender_profile, amount);
        types::increment_tips_sent(sender_profile);
        types::increment_total_received(receiver_profile, amount);
        types::increment_tips_received(receiver_profile);
    }
}
