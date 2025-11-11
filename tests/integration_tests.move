#[test_only]
module tipping::integration_tests {
    use sui::coin::Self;
    use sui::sui::SUI;
    use sui::test_scenario::Self;

    use tipping::tip_operations;
    use tipping::profile;
    use tipping::system_queries;
    use tipping::types::{UserProfile, TippingSystem};
    use tipping::test_helpers;

    // ============ Tests -  Integração ============

    #[test]
    fun test_complete_flow_multiple_users() {
        let mut scenario = test_scenario::begin(@0x1);
        let alice = @0x1;
        let bob = @0x2;
        let charlie = @0x3;

        // Cria system
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

        test_scenario::next_tx(&mut scenario, charlie);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile(b"Charlie", ctx);
        };

        // Get profiles
        test_scenario::next_tx(&mut scenario, alice);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, bob);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, charlie);
        let mut charlie_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Alice -> Bob (1 SUI)
        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000, ctx);
            tip_operations::send_tip(&mut system, &mut alice_profile, &mut bob_profile, coin, b"A->B", ctx);
        };

        // Bob -> Charlie (2 SUI)
        test_scenario::next_tx(&mut scenario, bob);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(2000000000, ctx);
            tip_operations::send_tip(&mut system, &mut bob_profile, &mut charlie_profile, coin, b"B->C", ctx);
        };

        // Charlie -> Alice (3 SUI)
        test_scenario::next_tx(&mut scenario, charlie);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(3000000000, ctx);
            tip_operations::send_tip(&mut system, &mut charlie_profile, &mut alice_profile, coin, b"C->A", ctx);
        };

        // Verify statistics do system
        assert!(system_queries::total_tips(&system) == 3, 0);
        assert!(system_queries::total_volume(&system) == 6000000000, 0);
        assert!(system_queries::history_size(&system) == 3, 0);

        // Verify statistics individuais
        assert!(profile::profile_total_sent(&alice_profile) == 1000000000, 0);
        assert!(profile::profile_total_received(&alice_profile) == 3000000000, 0);
        
        assert!(profile::profile_total_sent(&bob_profile) == 2000000000, 0);
        assert!(profile::profile_total_received(&bob_profile) == 1000000000, 0);
        
        assert!(profile::profile_total_sent(&charlie_profile) == 3000000000, 0);
        assert!(profile::profile_total_received(&charlie_profile) == 2000000000, 0);

        // Return objects
        test_scenario::return_shared(system);
        test_scenario::return_to_address(alice, alice_profile);
        test_scenario::return_to_address(bob, bob_profile);
        test_scenario::return_to_address(charlie, charlie_profile);

        test_scenario::end(scenario);
    }
}

