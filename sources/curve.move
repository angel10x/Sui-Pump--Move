/// Module: pumpfun::curve
/// 
/// Implements bonding curve-based token economics for the Sui blockchain. 
/// This module contains all primitives and logic needed for minting, trading, migrating, and administrating tokens under a bonding curve, including event emission, fee management, and migration functions. 
/// Structs and methods are provided for full on-chain curve lifecycle and fee configuration.
module pumpfun::curve {
    use sui::event::{Self};
    use std::string;
    use std::type_name;
    use sui::balance;
    use sui::sui::{SUI};
    use sui::coin;
    use std::ascii;
    use pumpfun::freezer;


    const ETotalSupplyNotEqualZero: u64 = 0;
    const EOutputAmountLessThanMin: u64 = 1;
    const EDecimalsNotEqualNine: u64 = 2;
    const EListingFeeNotEqual: u64 = 3;
    const ECurveNotActive: u64 = 4;
    const EReserveValuesNotGreaterThanZero: u64 = 5;
    const ECurveNotInactive: u64 = 6;

    /// Bonding curve object. Holds liquidity pool state, configuration, and social fields for token projects.
    public struct BondingCurve<phantom T> has key {
        id: UID,
        sui_balance: balance::Balance<SUI>,
        token_balance: balance::Balance<T>,
        virtual_sui_amt: u64,
        target_supply_threshold: u64,
        swap_fee: u64,
        is_active: bool,
        creator: address,
        twitter: option::Option<ascii::String>,
        telegram: option::Option<ascii::String>,
        website: option::Option<ascii::String>,
        migration_target: u64,
    }

    /// Global configuration state for bonding curve system. Manages migration, listing, swap fees, and system fee accumulation.
    public struct Configurator has key {
        id: UID,
        virtual_sui_amt: u64,
        target_supply_threshold: u64,
        migration_fee: u64,
        listing_fee: u64,
        swap_fee: u64,
        fee: balance::Balance<SUI>,
    }

    /// Emitted on bonding curve listing.
    public struct BondingCurveListedEvent has copy, drop {
        object_id: object::ID,
        token_type: ascii::String,
        sui_balance_val: u64,
        token_balance_val: u64,
        virtual_sui_amt: u64,
        target_supply_threshold: u64,
        creator: address,
        ticker: ascii::String,
        name: string::String,
        description: string::String,
        url: option::Option<0x2::url::Url>,
        coin_metadata_id: object::ID,
        twitter: option::Option<ascii::String>,
        telegram: option::Option<ascii::String>,
        website: option::Option<ascii::String>,
        migration_target: u64,
    }

    /// Emitted for every fee paid in the system, can be used for user or volume based reward systems.
    public struct Points has copy, drop {
        amount: u64,
        sender: address,
    }

    /// Emitted for every swap executed (buy or sell).
    public struct SwapEvent has copy, drop {
        bc_id: object::ID,
        token_type: ascii::String,
        is_buy: bool,
        input_amount: u64,
        output_amount: u64,
        sui_reserve_val: u64,
        token_reserve_val: u64,
        sender: address,
    }

    /// Emitted when a migration process is initiated (bonding curve deactivation).
    public struct MigrationPendingEvent has copy, drop {
        bc_id: object::ID,
        token_type: ascii::String,
        sui_reserve_val: u64,
        token_reserve_val: u64,
    }
    /// Emitted when a migration process completes (funds successfully migrated).
    public struct MigrationCompletedEvent has copy, drop {
        adapter_id: u64,
        bc_id: object::ID,
        token_type: ascii::String,
        target_pool_id: object::ID,
        sui_balance_val: u64,
        token_balance_val: u64,
    }

    /// Administration capability object for system configuration management. Only needed by system admin.
    public struct AdminCap has store, key {
        id: UID,
    }

    #[allow(lint(share_owned))]
    public fun transfer<T>(arg0: BondingCurve<T>) {
        transfer::share_object<BondingCurve<T>>(arg0);
    }

    public fun freeze_tr<T>(
        arg1: coin::TreasuryCap<T>,
        arg2: &mut tx_context::TxContext
    ) {
        freezer::freeze_object<coin::TreasuryCap<T>>(arg1,arg2);
    }

    public fun freeze_meta<T>(
        arg1: coin::CoinMetadata<T>,
        arg2: &mut tx_context::TxContext
    ) {
        freezer::freeze_object<coin::CoinMetadata<T>>(arg1,arg2);
    }

    public fun buy<T>(
        arg0: &mut BondingCurve<T>,
        arg1: &mut Configurator,
        arg2: coin::Coin<SUI>,
        arg3: u64,
        arg4: &mut tx_context::TxContext
    ) : coin::Coin<T> {
        assert!(arg0.is_active, ECurveNotActive);
        let v0 = tx_context::sender(arg4);
        let mut v1 = coin::into_balance<SUI>(arg2);
        take_fee(arg1, arg0.swap_fee, &mut v1, v0);
        let (v2, v3) = get_reserves<T>(arg0);
        let v4 = balance::value<SUI>(&v1);
        let v5 = get_output_amount(v4, v2 + arg0.virtual_sui_amt, v3);
        assert!(v5 >= arg3, EOutputAmountLessThanMin);
        balance::join<SUI>(&mut arg0.sui_balance, v1);
        let (v6, v7) = get_reserves<T>(arg0);
        assert!(v6 > 0 && v7 > 0, EReserveValuesNotGreaterThanZero);
        if (v7 <= arg0.target_supply_threshold) {
            arg0.is_active = false;
            emit_migration_pending_event(object::id<BondingCurve<T>>(arg0), type_name::into_string(type_name::get<T>()), v6, v7);
        };
        emit_swap_event(object::id<BondingCurve<T>>(arg0), type_name::into_string(type_name::get<T>()), true, v4, v5, v6, v7, v0);
        coin::take<T>(&mut arg0.token_balance, v5, arg4)
    }

    public fun confirm_migration(
        _arg0: &AdminCap,
        arg1: u64,
        arg2: object::ID,
        arg3: ascii::String,
        arg4: object::ID,
        arg5: u64,
        arg6: u64
    ) {
        emit_migration_completed_event(arg1, arg2, arg3, arg4, arg5, arg6);
    }

    fun emit_bonding_curve_event<T>(
        arg0: &BondingCurve<T>,
        arg1: ascii::String,
        arg2: string::String,
        arg3: string::String,
        arg4: option::Option<0x2::url::Url>,
        arg5: object::ID
    ) {
        let v0 = BondingCurveListedEvent{
            object_id               : object::id<BondingCurve<T>>(arg0),
            token_type              : type_name::into_string(type_name::get<T>()),
            sui_balance_val         : balance::value<SUI>(&arg0.sui_balance),
            token_balance_val       : balance::value<T>(&arg0.token_balance),
            virtual_sui_amt         : arg0.virtual_sui_amt,
            target_supply_threshold : arg0.target_supply_threshold,
            creator                 : arg0.creator,
            ticker                  : arg1,
            name                    : arg2,
            description             : arg3,
            url                     : arg4,
            coin_metadata_id        : arg5,
            twitter                 : arg0.twitter,
            telegram                : arg0.telegram,
            website                 : arg0.website,
            migration_target        : arg0.migration_target,
        };
        event::emit<BondingCurveListedEvent>(v0);
    }

    fun emit_migration_completed_event(
        arg0: u64,
        arg1: object::ID,
        arg2: ascii::String,
        arg3: object::ID,
        arg4: u64,
        arg5: u64
    ) {
        let v0 = MigrationCompletedEvent{
            adapter_id        : arg0,
            bc_id             : arg1,
            token_type        : arg2,
            target_pool_id    : arg3,
            sui_balance_val   : arg4,
            token_balance_val : arg5,
        };
        event::emit<MigrationCompletedEvent>(v0);
    }

    fun emit_migration_pending_event(
        arg0: object::ID,
        arg1: ascii::String,
        arg2: u64,
        arg3: u64
    ) {
        let v0 = MigrationPendingEvent{
            bc_id             : arg0,
            token_type        : arg1,
            sui_reserve_val   : arg2,
            token_reserve_val : arg3,
        };
        event::emit<MigrationPendingEvent>(v0);
    }

    fun emit_swap_event(
        arg0: object::ID,
        arg1: ascii::String,
        arg2: bool,
        arg3: u64,
        arg4: u64,
        arg5: u64,
        arg6: u64,
        arg7: address
    ) {
        let v0 = SwapEvent{
            bc_id             : arg0,
            token_type        : arg1,
            is_buy            : arg2,
            input_amount      : arg3,
            output_amount     : arg4,
            sui_reserve_val   : arg5,
            token_reserve_val : arg6,
            sender            : arg7,
        };
        event::emit<SwapEvent>(v0);
    }

    fun get_coin_metadata_info<T>(
        arg0: &coin::CoinMetadata<T>
    ) : (
        ascii::String,
        string::String,
        string::String,
        option::Option<0x2::url::Url>
    ) {
        (
            coin::get_symbol<T>(arg0),
            coin::get_name<T>(arg0),
            coin::get_description<T>(arg0),
            coin::get_icon_url<T>(arg0)
        )
    }

    public fun get_info<T>(
        arg0: &BondingCurve<T>
    ) : (u64, u64, u64, u64, bool) {
        (
            balance::value<SUI>(&arg0.sui_balance),
            balance::value<T>(&arg0.token_balance),
            arg0.virtual_sui_amt,
            arg0.target_supply_threshold,
            arg0.is_active
        )
    }

    fun get_output_amount(
        arg0: u64,
        arg1: u64,
        arg2: u64
    ) : u64 {
        let v0 = arg0 as u128;
        (v0 * (arg2 as u128) / ((arg1 as u128) + v0)) as u64
    }

    fun get_reserves<T>(arg0: &BondingCurve<T>) : (u64, u64) {
        (balance::value<SUI>(&arg0.sui_balance), balance::value<T>(&arg0.token_balance))
    }

    fun init(arg0: &mut tx_context::TxContext) {
        let v0 = AdminCap{id: object::new(arg0)};
        transfer::transfer<AdminCap>(v0, tx_context::sender(arg0));
        let v1 = Configurator{
            id                      : object::new(arg0),
            virtual_sui_amt         : 4200000000000,
            target_supply_threshold : 300000000000000000,
            migration_fee           : 300000000000,
            listing_fee             : 1000000000,
            swap_fee                : 10000,
            fee                     : balance::zero<SUI>(),
        };
        transfer::share_object<Configurator>(v1);
    }


    public fun list<T>(
        arg0: &mut Configurator, // 基础配置
        arg1: &mut coin::TreasuryCap<T>, // TreasuryCap
        arg2: &coin::CoinMetadata<T>, // CoinMetaData
        arg3: coin::Coin<SUI>, // 手续费
        arg4: option::Option<ascii::String>, // twitter
        arg5: option::Option<ascii::String>, // telegram
        arg6: option::Option<ascii::String>, // website
        arg7: u64, // 迁移目标价
        arg8: &mut tx_context::TxContext
    ) {
        assert!(coin::total_supply<T>(arg1) == 0, ETotalSupplyNotEqualZero);
        assert!(coin::get_decimals<T>(arg2) == 9, EDecimalsNotEqualNine);
        let mut v0 = coin::into_balance<SUI>(arg3);
        assert!(balance::value<SUI>(&v0) == arg0.listing_fee, EListingFeeNotEqual);

        balance::join<SUI>(&mut arg0.fee, balance::split<SUI>(&mut v0, arg0.listing_fee));
        let v1 = BondingCurve<T>{
            id                      : object::new(arg8),
            sui_balance             : v0,
            token_balance           : coin::mint_balance<T>(arg1, 1000000000000000000),
            virtual_sui_amt         : arg0.virtual_sui_amt,
            target_supply_threshold : arg0.target_supply_threshold,
            swap_fee                : arg0.swap_fee,
            is_active               : true,
            creator                 : tx_context::sender(arg8),
            twitter                 : arg4,
            telegram                : arg5,
            website                 : arg6,
            migration_target        : arg7,
        };
        let (v2, v3, v4, v5) = get_coin_metadata_info<T>(arg2);
        emit_bonding_curve_event<T>(&v1, v2, v3, v4, v5, object::id<coin::CoinMetadata<T>>(arg2));
        transfer::share_object<BondingCurve<T>>(v1);
    }

    public fun migrate<T>(
        _arg0: &AdminCap, arg1:
        &mut BondingCurve<T>,
        arg2: &mut Configurator,
        arg3: &mut tx_context::TxContext
    ) : (
        coin::Coin<SUI>,
        coin::Coin<T>
    ) {
        assert!(!arg1.is_active, ECurveNotInactive);
        if (arg2.migration_fee > 0) {
            balance::join<SUI>(&mut arg2.fee, balance::split<SUI>(&mut arg1.sui_balance, arg2.migration_fee));
        };
        let (v0, v1) = get_reserves<T>(arg1);
        (coin::from_balance<SUI>(balance::split<SUI>(&mut arg1.sui_balance, v0), arg3), coin::from_balance<T>(balance::split<T>(&mut arg1.token_balance, v1), arg3))
    }

    public fun sell<T>(
        arg0: &mut BondingCurve<T>,
        arg1: &mut Configurator,
        arg2: coin::Coin<T>,
        arg3: u64,
        arg4: &mut tx_context::TxContext
    ) : coin::Coin<SUI> {
        assert!(arg0.is_active, ECurveNotActive);
        let v0 = coin::into_balance<T>(arg2);
        let (v1, v2) = get_reserves<T>(arg0);
        let v3 = balance::value<T>(&v0);
        let v4 = get_output_amount(v3, v2, v1 + arg0.virtual_sui_amt);
        assert!(v4 >= arg3, EOutputAmountLessThanMin);
        balance::join<T>(&mut arg0.token_balance, v0);
        let mut v5 = balance::split<SUI>(&mut arg0.sui_balance, v4);
        take_fee(arg1, arg0.swap_fee, &mut v5, tx_context::sender(arg4));
        let (v6, v7) = get_reserves<T>(arg0);
        assert!(v6 > 0 && v7 > 0, EReserveValuesNotGreaterThanZero);
        emit_swap_event(object::id<BondingCurve<T>>(arg0), type_name::into_string(type_name::get<T>()), false, v3, balance::value<SUI>(&v5), v6, v7, tx_context::sender(arg4));
        coin::from_balance<SUI>(v5, arg4)
    }

    fun take_fee(
        arg0: &mut Configurator,
        arg1: u64,
        arg2: &mut balance::Balance<SUI>,
        arg3: address
    ) {
        let v0 = ((arg1 as u128) * (balance::value<SUI>(arg2) as u128) / 1000000) as u64;
        let v1 = Points{
            amount : v0,
            sender : arg3,
        };
        event::emit<Points>(v1);
        balance::join<SUI>(&mut arg0.fee, balance::split<SUI>(arg2, v0));
    }

    public fun update_listing_fee(
        _arg0: &AdminCap,
        arg1: &mut Configurator,
        arg2: u64
    ) {
        arg1.listing_fee = arg2;
    }

    public fun update_migration_fee(
        _arg0: &AdminCap,
        arg1: &mut Configurator,
        arg2: u64
    ) {
        arg1.migration_fee = arg2;
    }

    public fun update_target_supply_threshold(
        _arg0: &AdminCap,
        arg1: &mut Configurator,
        arg2: u64
    ) {
        arg1.target_supply_threshold = arg2;
    }

    public fun update_virtual_sui_liq(
        _arg0: &AdminCap,
        arg1: &mut Configurator,
        arg2: u64
    ) {
        arg1.virtual_sui_amt = arg2;
    }

    public fun withdraw_fee(
        _arg0: &AdminCap,
        arg1: &mut Configurator,
        arg2: &mut tx_context::TxContext
    ): coin::Coin<SUI> {
        let fee_value = balance::value<SUI>(&arg1.fee);
        coin::from_balance<SUI>(balance::split<SUI>(&mut arg1.fee, fee_value), arg2)
    }
}