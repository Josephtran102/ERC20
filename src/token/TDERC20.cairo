#[contract]
mod TDERC20 {
    // Core library Imports
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    use starknet::contract_address_const;
    use starknet::ContractAddressZeroable;
    use starknet::ContractAddressIntoFelt;
    use starknet::FeltTryIntoContractAddress;
    use starknet::contract_address_try_from_felt;
    use traits::Into;
    use traits::TryInto;
    use array::ArrayTrait;
    use option::OptionTrait;
    use integer::u256_from_felt;

    // Internal Imports
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_name;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_symbol;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_totalSupply;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_decimals;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_balanceOf;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_allowance;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_mint;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_burn;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_initializer;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_approve;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_increaseAllowance;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_decreaseAllowance;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_transfer;
    use starknet_cairo_101::token::ERC20_base::ERC20Base::ERC20_transferFrom;

    struct Storage {
        is_transferable_storage: bool,
        teachers_and_exercises_accounts: LegacyMap<ContractAddress, bool>,
    }

    ////////////////////////////////
    // Events
    ////////////////////////////////
    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}

    ////////////////////////////////
    // View FUNCTIONS
    ////////////////////////////////
    #[view]
    fn is_transferable() -> bool {
        is_transferable_storage::read()
    }

    #[view]
    fn name() -> felt {
        ERC20_name()
    }

    #[view]
    fn symbol() -> felt {
        ERC20_symbol()
    }

    #[view]
    fn decimals() -> u8 {
        ERC20_decimals()
    }

    #[view]
    fn get_total_supply() -> u256 {
        ERC20_totalSupply()
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        ERC20_balanceOf(account)
    }

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
        ERC20_allowance(owner, spender)
    }

    #[view]
    fn is_teacher_or_exercise(account: ContractAddress) -> bool {
        teachers_and_exercises_accounts::read(account)
    }

    ////////////////////////////////
    // Constructor
    ////////////////////////////////
    #[constructor]
    fn constructor(
        name_: felt, symbol_: felt, decimals_: u8, initial_supply: u256, recipient: ContractAddress
    ) {
        ERC20_initializer(name_, symbol_, decimals_, initial_supply, recipient);
        Transfer(contract_address_const::<0>(), recipient, initial_supply);
    }


    ////////////////////////////////
    // EXTERNAL FUNCTIONS
    ////////////////////////////////
    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) -> bool {
       _is_transferable();
       ERC20_transfer(recipient, amount);
       return true;
    }

    #[external]
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool {
        _is_transferable();
        ERC20_transferFrom(sender, recipient, amount);
        Transfer(sender, recipient, amount);
        return true;
    }

    #[external]
    fn approve(spender: ContractAddress, amount: u256) -> bool {
        ERC20_approve(spender, amount);
        let owner: ContractAddress = get_caller_address();
        Approval(owner, spender, amount);
        return true;
    }

    #[external]
    fn increase_allowance(spender: ContractAddress, added_value: u256) -> bool {
        ERC20_increaseAllowance(spender, added_value);
        return true;
    }

    #[external]
    fn decrease_allowance(spender: ContractAddress, subtracted_value: u256) -> bool {
        ERC20_decreaseAllowance(spender, subtracted_value);
        return true;
    }

    #[external]
    fn distribute_points(to: ContractAddress, amount: u256) {
        only_teacher_or_exercise();
        ERC20_mint(to, amount);
    }

    #[external]
    fn remove_points(to: ContractAddress, amount: u256) {
        only_teacher_or_exercise();
        ERC20_burn(to, amount);
    }

    #[external]
    fn set_teacher(account: ContractAddress, permission: bool) {
        only_teacher_or_exercise();
        teachers_and_exercises_accounts::write(account, permission);
    }

    #[external]
    fn set_transferable(permission: bool) {
        only_teacher_or_exercise();
        is_transferable_storage::write(permission);
        return ();
    }

    ////////////////////////////////
    // INTERNAL FUNCTIONS
    ////////////////////////////////
    fn only_teacher_or_exercise() {
        let caller = get_caller_address();
        let permission = teachers_and_exercises_accounts::read(caller);
        assert(permission == true, 'NO_PERMISSION');
    }

    fn _is_transferable() {
        let permission = is_transferable_storage::read();
        assert(permission == true, 'NOT_TRANSFERABLE');
    }
}