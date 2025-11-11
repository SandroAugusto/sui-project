#[test_only]
module tipping::profile_tests {
    use sui::test_scenario::Self;

    use tipping::profile;
    use tipping::types::UserProfile;
    use tipping::test_helpers;
    use std::string;

    // ============ Profile Tests - Happy Paths ============

    #[test]
    fun test_create_profile_success() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Create system
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };
        
        // Create profile successfully
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_multiple_profiles() {
        let mut scenario = test_scenario::begin(@0x1);
        let bob = @0x2;
        let charlie = @0x3;

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
        test_scenario::next_tx(&mut scenario, bob);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        // Create Charlie's profile
        test_scenario::next_tx(&mut scenario, charlie);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Charlie", ctx);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_profile_long_name() {
        let mut scenario = test_scenario::begin(@0x1);
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"John Smith Johnson Williams", ctx);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_profile_name_with_special_chars() {
        let mut scenario = test_scenario::begin(@0x1);
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"User_123", ctx);
        };

        test_scenario::end(scenario);
    }

    // ============ Profile Tests - Queries ============

    #[test]
    fun test_query_profile_statistics_empty() {
        let mut scenario = test_scenario::begin(@0x1);
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };

        test_scenario::next_tx(&mut scenario, @0x1);
        let profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Verify initial statistics
        let (addr, name, received, sent, tips_received, tips_sent) = 
            profile::profile_statistics(&profile);
        
        assert!(addr == @0x1, 0);
        assert!(name == string::utf8(b"Alice"), 0);
        assert!(received == 0, 0);
        assert!(sent == 0, 0);
        assert!(tips_received == 0, 0);
        assert!(tips_sent == 0, 0);

        test_scenario::return_to_address(@0x1, profile);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_query_profile_name() {
        let mut scenario = test_scenario::begin(@0x1);
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        test_scenario::next_tx(&mut scenario, @0x1);
        let profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        let name = profile::profile_name(&profile);
        assert!(name == string::utf8(b"Bob"), 0);

        test_scenario::return_to_address(@0x1, profile);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_query_profile_address() {
        let mut scenario = test_scenario::begin(@0x1);
        let test_address = @0x42;
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };
        
        test_scenario::next_tx(&mut scenario, test_address);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Test", ctx);
        };

        test_scenario::next_tx(&mut scenario, test_address);
        let profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        let addr = profile::profile_address(&profile);
        assert!(addr == test_address, 0);

        test_scenario::return_to_address(test_address, profile);
        test_scenario::end(scenario);
    }

    // ============ Statistics Tests ============

    #[test]
    fun test_profile_statistics_complete() {
        let mut scenario = test_scenario::begin(@0x1);
        let alice = @0x1;
        let bob = @0x2;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        test_scenario::next_tx(&mut scenario, bob);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        test_scenario::next_tx(&mut scenario, alice);
        let mut system = test_scenario::take_shared<tipping::types::TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, bob);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Send tip
        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = sui::coin::mint_for_testing<sui::sui::SUI>(5000000000, ctx); // 5 SUI
            tipping::tip_operations::send_tip(
                &mut system,
                &mut alice_profile,
                &mut bob_profile,
                coin,
                b"Test",
                ctx
            );
        };

        // Verify complete statistics
        let (addr, name, received, sent, tips_received, tips_sent) = 
            profile::profile_statistics(&alice_profile);
        
        assert!(addr == alice, 0);
        assert!(name == string::utf8(b"Alice"), 0);
        assert!(sent == 5000000000, 0);
        assert!(received == 0, 0);
        assert!(tips_sent == 1, 0);
        assert!(tips_received == 0, 0);

        // Verify receiver statistics
        let (bob_addr, bob_name, bob_received, bob_sent, bob_tips_received, bob_tips_sent) = 
            profile::profile_statistics(&bob_profile);
        
        assert!(bob_addr == bob, 0);
        assert!(bob_name == string::utf8(b"Bob"), 0);
        assert!(bob_received == 5000000000, 0);
        assert!(bob_sent == 0, 0);
        assert!(bob_tips_received == 1, 0);
        assert!(bob_tips_sent == 0, 0);

        test_scenario::return_shared(system);
        test_scenario::return_to_address(alice, alice_profile);
        test_scenario::return_to_address(bob, bob_profile);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_profile_statistics_bidirectional() {
        let mut scenario = test_scenario::begin(@0x1);
        let alice = @0x1;
        let bob = @0x2;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Alice", ctx);
        };
        
        test_scenario::next_tx(&mut scenario, bob);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Bob", ctx);
        };

        test_scenario::next_tx(&mut scenario, alice);
        let mut system = test_scenario::take_shared<tipping::types::TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, bob);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Alice sends to Bob
        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin1 = sui::coin::mint_for_testing<sui::sui::SUI>(1000000000, ctx);
            tipping::tip_operations::send_tip(&mut system, &mut alice_profile, &mut bob_profile, coin1, b"A->B", ctx);
        };

        // Bob sends to Alice
        test_scenario::next_tx(&mut scenario, bob);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin2 = sui::coin::mint_for_testing<sui::sui::SUI>(2000000000, ctx);
            tipping::tip_operations::send_tip(&mut system, &mut bob_profile, &mut alice_profile, coin2, b"B->A", ctx);
        };

        // Verify bidirectional statistics
        assert!(profile::profile_total_sent(&alice_profile) == 1000000000, 0);
        assert!(profile::profile_total_received(&alice_profile) == 2000000000, 0);
        assert!(profile::profile_total_sent(&bob_profile) == 2000000000, 0);
        assert!(profile::profile_total_received(&bob_profile) == 1000000000, 0);

        test_scenario::return_shared(system);
        test_scenario::return_to_address(alice, alice_profile);
        test_scenario::return_to_address(bob, bob_profile);

        test_scenario::end(scenario);
    }
}
