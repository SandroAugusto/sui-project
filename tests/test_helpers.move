#[test_only]
module tipping::test_helpers {
    use sui::tx_context;
    use tipping::types;

    /// Creates the tipping system for tests
    public fun create_test_system(ctx: &mut tx_context::TxContext) {
        let system = types::create_system(ctx);
        types::share_system(system);
    }
}
