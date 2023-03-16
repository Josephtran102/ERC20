// ######## Ex 13
// Privacy
// The terminology "Zero knowldge" can be confusing. Devs tend to assume things are private on Zk Rollups.
// They are not. They can be; but they are not by default.
// In this exercise, you need to:
// - Use past data from transactions sent to the contract to find a value that is supposed to be "secret"
// you might need this endpoint https://alpha4.starknet.io/feeder_gateway/get_transaction?transactionHash=

#[contract]
mod Ex12 {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::ContractAddressZeroable;
    use starknet::ContractAddressIntoFelt;
    use starknet::FeltTryIntoContractAddress;
    use starknet::contract_address_try_from_felt;
    use starknet::contract_address_to_felt;
    use traits::Into;
    use traits::TryInto;
    use array::ArrayTrait;
    use option::OptionTrait;
    use integer::u256_from_felt;

    // Internal Imports
    use starknet_cairo_101::utils::ex00_base::Ex00Base::tderc20_address;
    use starknet_cairo_101::utils::ex00_base::Ex00Base::has_validated_exercise;
    use starknet_cairo_101::utils::ex00_base::Ex00Base::distribute_points;
    use starknet_cairo_101::utils::ex00_base::Ex00Base::validate_exercise;
    use starknet_cairo_101::utils::ex00_base::Ex00Base::ex_initializer;

    ////////////////////////////////
    // STORAGE
    ////////////////////////////////
    struct Storage {
        user_slots: LegacyMap::<felt, felt>,
        values_mapped_secret: LegacyMap::<felt, felt>,
        was_initialized: bool,
        next_slot: felt,
    }

    ////////////////////////////////
    // EVENTS
    ////////////////////////////////
    #[event]
    fn Assign_User_Slot_Called(account: ContractAddress, rank: felt) {}

    ////////////////////////////////
    // Constructor
    ////////////////////////////////
    #[constructor]
    fn constructor(
        _tderc20_address: felt,
        _players_registry: felt,
        _workshop_id: felt,
        _exercise_id: felt,
        values: Array::<felt>
    ) {
        ex_initializer(_tderc20_address, _players_registry, _workshop_id, _exercise_id);
        set_random_values(values);
    }

    ////////////////////////////////
    // View Functions
    ////////////////////////////////
    #[view]
    fn get_user_slots(account: felt) -> felt {
        return user_slots::read(account);
    }

    ////////////////////////////////
    // EXTERNAL FUNCTIONS
    ////////////////////////////////

    #[external]
    fn claim_points(expected_value: felt) {
        // Reading caller address
        let sender_address: ContractAddress = get_caller_address();
        // Checking that the user got a slot assigned
        let user_slot = user_slots::read(sender_address.into());
        assert(user_slot != 0, 'ASSIGN_USER_SLOT_FIRST');

        // Checking that the value provided by the user is the one we expect
        // Still sneaky.
        // Or not. Is this psyops?
        let value = values_mapped_secret::read(user_slot);
        assert(value == expected_value, 'NOT_EXPECTED_SECRET_VALUE');

        // Checking if the user has validated the exercise before
        validate_exercise(sender_address.into());
        // Sending points to the address specified as parameter
        distribute_points(sender_address.into(), u256_from_felt(2));
    }

    #[external]
    fn assign_user_slot() {
        // Reading caller address
        let sender_address: ContractAddress = get_caller_address();
        let next_slot_temp = next_slot::read();
        let next_value = values_mapped_secret::read(next_slot_temp + 1);
        if next_value == 0 {
            user_slots::write(sender_address.into(), 1);
            next_slot::write(0);
        } else {
            user_slots::write(sender_address.into(), next_slot_temp + 1);
            next_slot::write(next_slot_temp + 1);
        }

        let user_slot = user_slots::read(sender_address.into());
        // Emit an event with secret value
        Assign_User_Slot_Called(sender_address, user_slot);
    }

    //
    // External functions - Administration
    // Only admins can call these. You don't need to understand them to finish the exercise.
    //
    #[external]
    fn set_random_values(values: Array::<felt>) {
        // Check if the random values were already initialized
        let was_initialized_read = was_initialized::read();
        assert(was_initialized_read == true, 'NOT_INITIALISED');

        let mut idx: felt = 0;
        set_a_random_value(idx, values);

        // Mark that value store was initialized
        was_initialized::write(true);
    }

    fn set_a_random_value(mut idx: felt, mut values: Array::<felt>) {
        if !values.is_empty() {
            values_mapped_secret::write(idx, values.pop_front().unwrap());
            idx = idx + 1;
            set_a_random_value(idx, values);
        }
    }
}