#[test_only]
module tipping::system_queries_tests {
    use sui::coin::Self;
    use sui::sui::SUI;
    use sui::test_scenario::Self;

    use tipping::system_queries;
    use tipping::tip_operations;
    use tipping::profile;
    use tipping::types::{UserProfile, TippingSystem};
    use tipping::test_helpers;
    use std::option;
    use std::string;

    // ============ System Query Tests - Happy Paths ============

    #[test]
    fun test_query_empty_system() {
        let mut scenario = test_scenario::begin(@0x1);
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        test_scenario::next_tx(&mut scenario, @0x1);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);

        // Verifica system vazio
        assert!(system_queries::total_tips(&system) == 0, 0);
        assert!(system_queries::total_volume(&system) == 0, 0);
        assert!(system_queries::history_size(&system) == 0, 0);

        test_scenario::return_shared(system);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_query_history() {
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
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, bob);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000, ctx);
            tip_operations::send_tip(&mut system, &mut alice_profile, &mut bob_profile, coin, b"Test", ctx);
        };

        // Query history
        assert!(system_queries::history_size(&system) == 1, 0);
        
        let tip_opt = system_queries::get_tip(&system, 0);
        assert!(option::is_some(&tip_opt), 0);

        test_scenario::return_shared(system);
        test_scenario::return_to_address(alice, alice_profile);
        test_scenario::return_to_address(bob, bob_profile);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_query_history_multiple_tips() {
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
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, bob);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Envia 3 tips
        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin1 = coin::mint_for_testing<SUI>(1000000000, ctx);
            tip_operations::send_tip(&mut system, &mut alice_profile, &mut bob_profile, coin1, b"1", ctx);
        };

        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin2 = coin::mint_for_testing<SUI>(2000000000, ctx);
            tip_operations::send_tip(&mut system, &mut alice_profile, &mut bob_profile, coin2, b"2", ctx);
        };

        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin3 = coin::mint_for_testing<SUI>(3000000000, ctx);
            tip_operations::send_tip(&mut system, &mut alice_profile, &mut bob_profile, coin3, b"3", ctx);
        };

        // Verify history
        assert!(system_queries::history_size(&system) == 3, 0);
        
        let tip1 = system_queries::get_tip(&system, 0);
        let tip2 = system_queries::get_tip(&system, 1);
        let tip3 = system_queries::get_tip(&system, 2);
        
        assert!(option::is_some(&tip1), 0);
        assert!(option::is_some(&tip2), 0);
        assert!(option::is_some(&tip3), 0);

        test_scenario::return_shared(system);
        test_scenario::return_to_address(alice, alice_profile);
        test_scenario::return_to_address(bob, bob_profile);

        test_scenario::end(scenario);
    }

    // ============ Tests -  Consulta do Sistema - Unhappy Paths ============

    #[test]
    fun test_query_tip_invalid_index() {
        let mut scenario = test_scenario::begin(@0x1);
        
        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        test_scenario::next_tx(&mut scenario, @0x1);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);

        // Try to query invalid index in empty system
        let tip_opt = system_queries::get_tip(&system, 0);
        assert!(option::is_none(&tip_opt), 0);

        // Try to query very large index
        let tip_opt2 = system_queries::get_tip(&system, 999);
        assert!(option::is_none(&tip_opt2), 0);

        test_scenario::return_shared(system);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_query_tip_index_out_of_range() {
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
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        let mut alice_profile = test_scenario::take_from_sender<UserProfile>(&scenario);
        
        test_scenario::next_tx(&mut scenario, bob);
        let mut bob_profile = test_scenario::take_from_sender<UserProfile>(&scenario);

        // Envia apenas 1 tip
        test_scenario::next_tx(&mut scenario, alice);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000, ctx);
            tip_operations::send_tip(&mut system, &mut alice_profile, &mut bob_profile, coin, b"Test", ctx);
        };

        // Try to query invalid indices
        let tip_opt1 = system_queries::get_tip(&system, 1); // Out of range
        let tip_opt2 = system_queries::get_tip(&system, 100); // Very out of range
        
        assert!(option::is_none(&tip_opt1), 0);
        assert!(option::is_none(&tip_opt2), 0);

        // Valid index should work
        let tip_opt3 = system_queries::get_tip(&system, 0);
        assert!(option::is_some(&tip_opt3), 0);

        test_scenario::return_shared(system);
        test_scenario::return_to_address(alice, alice_profile);
        test_scenario::return_to_address(bob, bob_profile);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_lookup_address_by_handle() {
        let mut scenario = test_scenario::begin(@0x1);
        let alice = @0x1;

        {
            let ctx = test_scenario::ctx(&mut scenario);
            test_helpers::create_test_system(ctx);
        };

        test_scenario::next_tx(&mut scenario, alice);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            profile::create_profile_with_system(
                &mut system,
                string::utf8(b"Alice"),
                string::utf8(b"Creator"),
                string::utf8(b"alice_handle"),
                ctx
            );
        };
        test_scenario::return_shared(system);

        test_scenario::next_tx(&mut scenario, alice);
        let mut system = test_scenario::take_shared<TippingSystem>(&scenario);

        let result = system_queries::get_address_by_handle(&system, b"alice_handle");
        assert!(option::is_some(&result), 0);
        let resolved = option::destroy_some(result);
        assert!(resolved == alice, 0);

        test_scenario::return_shared(system);
        test_scenario::end(scenario);
    }

    // ============ Tests -  Conversão ============

    #[test]
    fun test_mist_to_sui() {
        assert!(system_queries::mist_to_sui(1000000000) == 1, 0);
        assert!(system_queries::mist_to_sui(5000000000) == 5, 0);
        assert!(system_queries::mist_to_sui(100000000) == 0, 0); // Less than 1 SUI
        assert!(system_queries::mist_to_sui(999999999) == 0, 0); // Almost 1 SUI
        assert!(system_queries::mist_to_sui(1000000001) == 1, 0); // A little more than 1 SUI
        assert!(system_queries::mist_to_sui(0) == 0, 0);
    }

    #[test]
    fun test_mist_to_sui_large_values() {
        assert!(system_queries::mist_to_sui(1000000000000) == 1000, 0); // 1000 SUI
        assert!(system_queries::mist_to_sui(10000000000000) == 10000, 0); // 10000 SUI
    }
}
