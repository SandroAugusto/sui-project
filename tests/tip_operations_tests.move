#[test_only]
module tipping::tip_operations_tests {
    use sui::coin::Self;
    use sui::sui::SUI;
    use sui::test_scenario::Self;

    use tipping::tip_operations;
    use tipping::profile;
    use tipping::system_queries;
    use tipping::types::{UserProfile, TippingSystem};
    use tipping::test_helpers;

    // ============ Tip Tests - Happy Paths ============

    #[test]
    fun test_send_tip_success() {
        let mut scenario = test_scenario::begin(@0x1);
        let sender = @0x1;
        let receiver = @0x2;

        // Create system
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        // Create Alice's profile
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        // Create Bob's profile
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        // Get profiles
        test_scenario::next_tx(&mut scenario, sender);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, receiver);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Send tip
        test_scenario::next_tx(&mut scenario, sender);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000, ctx); // 1 SUI

            tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut bob_profile,
                coin,
                b"Thanks for the great work!",
                ctx
            );
        };

        // Verify system statistics
        assert!(system_queries::total_tips(&system) == 1, 0);
        assert!(system_queries::total_volume(&system) == 1000000000, 0);
        assert!(system_queries::history_size(&system) == 1, 0);

        // Verify profile statistics
        assert!(profile::profile_total_sent(&alice_profile) == 1000000000, 0);
        assert!(profile::profile_total_received(&bob_profile) == 1000000000, 0);

        // Return objects
        test_scenario::return_shared(system);
        test_scenario::return_to_address(sender, alice_profile);
        test_scenario::return_to_address(receiver, bob_profile);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_send_multiple_tips() {
        let mut scenario = test_scenario::begin(@0x1);
        let alice = @0x1;
        let bob = @0x2;

        // Create system
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        // Create profiles
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        test_scenario::next_tx(&mut scenario, bob);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        // Get profiles
        test_scenario::next_tx(&mut scenario, alice);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, bob);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // First tip: Alice -> Bob (1 SUI)
        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin1 = coin::mint_for_testing<SUI>(1000000000, ctx);
            tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut bob_profile,
                coin1,
                b"First",
                ctx
            );
        };

        // Second tip: Alice -> Bob (2 SUI)
        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin2 = coin::mint_for_testing<SUI>(2000000000, ctx);
            tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut bob_profile,
                coin2,
                b"Second",
                ctx
            );
        };

        // Verify statistics
        assert!(system_queries::total_tips(&system) == 2, 0);
        assert!(system_queries::total_volume(&system) == 3000000000, 0);
        assert!(profile::profile_total_sent(&alice_profile) == 3000000000, 0);
        assert!(profile::profile_total_received(&bob_profile) == 3000000000, 0);

        // Return objects
        test_scenario::return_shared(system);
        test_scenario::return_to_address(alice, alice_profile);
        test_scenario::return_to_address(bob, bob_profile);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_send_tip_valor_pequeno() {
        let mut scenario = test_scenario::begin(@0x1);
        let sender = @0x1;
        let receiver = @0x2;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        test_scenario::next_tx(&mut scenario, sender);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, receiver);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Send tip with small value (1 MIST)
        test_scenario::next_tx(&mut scenario, sender);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1, ctx);

            tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut bob_profile,
                coin,
                b"Small tip",
                ctx
            );
        };

        assert!(system_queries::total_tips(&system) == 1, 0);
        assert!(system_queries::total_volume(&system) == 1, 0);

        test_scenario::return_shared(system);
        test_scenario::return_to_address(sender, alice_profile);
        test_scenario::return_to_address(receiver, bob_profile);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_send_tip_valor_grande() {
        let mut scenario = test_scenario::begin(@0x1);
        let sender = @0x1;
        let receiver = @0x2;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        test_scenario::next_tx(&mut scenario, sender);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, receiver);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Send tip with large value (1000 SUI)
        test_scenario::next_tx(&mut scenario, sender);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000000, ctx); // 1000 SUI

            tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut bob_profile,
                coin,
                b"Generous tip!",
                ctx
            );
        };

        assert!(system_queries::total_tips(&system) == 1, 0);
        assert!(system_queries::total_volume(&system) == 1000000000000, 0);
        assert!(profile::profile_total_sent(&alice_profile) == 1000000000000, 0);
        assert!(profile::profile_total_received(&bob_profile) == 1000000000000, 0);

        test_scenario::return_shared(system);
        test_scenario::return_to_address(sender, alice_profile);
        test_scenario::return_to_address(receiver, bob_profile);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_send_tip_mensagem_vazia() {
        let mut scenario = test_scenario::begin(@0x1);
        let sender = @0x1;
        let receiver = @0x2;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        test_scenario::next_tx(&mut scenario, sender);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, receiver);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Send tip with empty message
        test_scenario::next_tx(&mut scenario, sender);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000, ctx);

            tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut bob_profile,
                coin,
                b"", // Empty message
                ctx
            );
        };

        assert!(system_queries::total_tips(&system) == 1, 0);

        test_scenario::return_shared(system);
        test_scenario::return_to_address(sender, alice_profile);
        test_scenario::return_to_address(receiver, bob_profile);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_send_tip_mensagem_longa() {
        let mut scenario = test_scenario::begin(@0x1);
        let sender = @0x1;
        let receiver = @0x2;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        test_scenario::next_tx(&mut scenario, sender);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, receiver);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Send tip with long message
        test_scenario::next_tx(&mut scenario, sender);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000, ctx);

            tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut bob_profile,
                coin,
                b"This is a very long message to test if the system can handle extensive messages without problems",
                ctx
            );
        };

        assert!(system_queries::total_tips(&system) == 1, 0);

        test_scenario::return_shared(system);
        test_scenario::return_to_address(sender, alice_profile);
        test_scenario::return_to_address(receiver, bob_profile);

        test_scenario::end(scenario);
    }

    // ============ Tests -  Gorjeta - Unhappy Paths ============

    #[test]
    #[expected_failure(abort_code = 1)] // E_INVALID_VALUE
    fun test_tip_zero_value() {
        let mut scenario = test_scenario::begin(@0x1);
        let sender = @0x1;
        let receiver = @0x2;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        test_scenario::next_tx(&mut scenario, sender);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, receiver);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        test_scenario::next_tx(&mut scenario, sender);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(0, ctx);

            tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut bob_profile,
                coin,
                b"Test",
                ctx
            );
        };

        test_scenario::return_shared(system);
        test_scenario::return_to_address(sender, alice_profile);
        test_scenario::return_to_address(receiver, bob_profile);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)] // E_SAME_USER
    fun test_tip_to_self() {
        let mut scenario = test_scenario::begin(@0x1);
        let sender = @0x1;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice2", ctx);
        };

        test_scenario::next_tx(&mut scenario, sender);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        let mut alice_profile_dest = test_scenario::take_from_sender<UserProfile>(&scenario);

        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000, ctx);

            tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut alice_profile_dest,
                coin,
                b"Test",
                ctx
            );
        };

        test_scenario::return_shared(system);
        test_scenario::return_to_address(sender, alice_profile);
        test_scenario::return_to_address(sender, alice_profile_dest);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)] // E_PROFILE_NOT_EXISTS
    fun test_tip_sender_profile_incorrect() {
        let mut scenario = test_scenario::begin(@0x1);
        let sender = @0x1;
        let receiver = @0x2;
        let impostor = @0x3;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        // Get system and profiles
        test_scenario::next_tx(&mut scenario, sender);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, receiver);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Impostor tries to send tip using Alice profile (which does not belong to him)
        test_scenario::next_tx(&mut scenario, impostor);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000, ctx);

            tip_operations::send_tip(
                &mut system,
                &mut alice_profile, // Alice profile, but sent by impostor
                &mut bob_profile,
                coin,
                b"Test",
                ctx
            );
        };

        test_scenario::return_shared(system);
        test_scenario::return_to_address(sender, alice_profile);
        test_scenario::return_to_address(receiver, bob_profile);
        test_scenario::end(scenario);
    }
}
