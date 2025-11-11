module tipping::tipping {
    use sui::tx_context::TxContext;

    use tipping::types::Self;

    // ============ Initialization Functions ============

    /// Module initialization function
    /// Creates the shared object for the tipping system
    fun init(ctx: &mut TxContext) {
        let system = types::create_system(ctx);
        types::share_system(system);
    }
}
