module tipping::errors {
    /// Error codes for the tipping system
    
    const E_PROFILE_NOT_EXISTS: u64 = 0;
    const E_INVALID_VALUE: u64 = 1;
    const E_SAME_USER: u64 = 2;
    const E_PROFILE_NOT_OWNED: u64 = 3;
    const E_INVALID_INDEX: u64 = 4;
    const E_HANDLE_TAKEN: u64 = 5;
    const E_INVALID_HANDLE: u64 = 6;
    const E_PROFILE_ALREADY_EXISTS: u64 = 7;

    public fun profile_not_exists(): u64 { E_PROFILE_NOT_EXISTS }
    public fun invalid_value(): u64 { E_INVALID_VALUE }
    public fun same_user(): u64 { E_SAME_USER }
    public fun profile_not_owned(): u64 { E_PROFILE_NOT_OWNED }
    public fun invalid_index(): u64 { E_INVALID_INDEX }
    public fun handle_taken(): u64 { E_HANDLE_TAKEN }
    public fun invalid_handle(): u64 { E_INVALID_HANDLE }
    public fun profile_already_exists(): u64 { E_PROFILE_ALREADY_EXISTS }
}
