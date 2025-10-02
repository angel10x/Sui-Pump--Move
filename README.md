## <div style="display: flex;justify-content: center; align-items: center;">SUI Pump.fun Smart Contract </div>
Welcome to pumpdotfun or pump.fun smart contract with the same functionality as before, such as adding virtual LP, removing LP, creating Raydium Pool. This is the Move smart contract of pump.fun.

## Project Workflow
The user connects their wallet -> begins creating a token -> enters information and uploads an avatar -> initiates token creation -> upon completion, the page automatically redirects to the token trading information page -> the user can then buy or sell the token.

## Structure

### BondingCurve

```rust
public struct BondingCurve<phantom T> has key {
    id: UID,  // Unique identifier
    sui_balance: balance::Balance<SUI>,  // SUI Token Balance
    token_balance: balance::Balance<T>,  // Other Token Balance
    virtual_sui_amt: u64,  // Number of Virtual SUI Tokens
    target_supply_threshold: u64,  // Target supply threshold
    swap_fee: u64,  // Exchange Fees
    is_active: bool,  // Activate
    creator: address,  // Creator Address
    twitter: option::Option<ascii::String>,  // Twitter
    telegram: option::Option<ascii::String>,  // Telegram
    website: option::Option<ascii::String>,  // Website
    migration_target: u64,  // Migration Target
}
```

### Configurator

```rust
public struct Configurator has key {
    id: UID,  // Unique identifier
    virtual_sui_amt: u64,  // Virtual SUI Amount
    target_supply_threshold: u64,  // Target supply threshold
    migration_fee: u64,  // Migration fee
    listing_fee: u64,  // Listing fee
    swap_fee: u64,  // Swap fee
    fee: balance::Balance<SUI>,  // Fee balance
}
```

### BondingCurveListedEvent

```rust
public struct BondingCurveListedEvent has copy, drop {
    object_id: object::ID,  // Object ID
    token_type: ascii::String,  // Token Type
    sui_balance_val: u64,  // SUI Token Balance
    token_balance_val: u64,  // Other Token Balance
    virtual_sui_amt: u64,  // Number of Virtual SUI Tokens
    target_supply_threshold: u64,  // Target supply threshold
    creator: address,  // Creator
    ticker: ascii::String,  // Ticker
    name: string::String,  // Name
    description: string::String,  // Descriptoin
    url: option::Option<0x2::url::Url>,  // URL
    coin_metadata_id: object::ID,  // Token Metadata ID
    twitter: option::Option<ascii::String>,  // Twitter
    telegram: option::Option<ascii::String>,  // Telegram
    website: option::Option<ascii::String>,  // Website
    migration_target: u64,  // Migration target
}
```

### Points

```rust
public struct Points has copy, drop {
    amount: u64,  // Amount
    sender: address,  // Sender
}
```

### SwapEvent

```rust
public struct SwapEvent has copy, drop {
    bc_id: object::ID,  // Object ID
    token_type: ascii::String,  // Token Type
    is_buy: bool,  // Is it a purchase
    input_amount: u64,  // Input Amount
    output_amount: u64,  // Output Amount
    sui_reserve_val: u64,  // SUI Reserve Value
    token_reserve_val: u64,  // Token Reserve Value
    sender: address,  // Sender
}
```

### MigrationPendingEvent

```rust
public struct MigrationPendingEvent has copy, drop {
    bc_id: object::ID,  // Object ID
    token_type: ascii::String,  // Token Type
    sui_reserve_val: u64,  // SUI Reserve
    token_reserve_val: u64,  // Token Reserve Value
}
```

### MigrationCompletedEvent

```rust
public struct MigrationCompletedEvent has copy, drop {
    adapter_id: u64,  // Adapter ID
    bc_id: object::ID,  // Object ID
    token_type: ascii::String,  // Token Type
    target_pool_id: object::ID,  // Target Pool ID
    sui_balance_val: u64,  // SUI Token Balance
    token_balance_val: u64,  // Other Token Balance
}
```

### AdminCap

```rust
public struct AdminCap has store, key {
    id: UID,  // Unique identifier
}
```

## Function

### Public Functions

### transfer

```rust
public fun transfer<T>(arg0: BondingCurve<T>) {
    transfer::share_object<BondingCurve<T>>(arg0);
}
```

- **arg0**: `BondingCurve<T>` - ObjectObject

### freeze_tr

```rust
public fun freeze_tr<T>(
    arg1: coin::TreasuryCap<T>,
    arg2: &mut tx_context::TxContext
) {
    freezer::freeze_object<coin::TreasuryCap<T>>(arg1, arg2);
}
```

- **arg1**: `coin::TreasuryCap<T>` - Token Financial Cap Object
- **arg2**: `&mut tx_context::TxContext` - Transaction context

### freeze_meta

```rust
public fun freeze_meta<T>(
    arg1: coin::CoinMetadata<T>,
    arg2: &mut tx_context::TxContext
) {
    freezer::freeze_object<coin::CoinMetadata<T>>(arg1, arg2);
}
```

- **arg1**: `coin::CoinMetadata<T>` - Token Metadata Object
- **arg2**: `&mut tx_context::TxContext` - Transaction context

### buy

```rust
public fun buy<T>(
    arg0: &mut BondingCurve<T>, 
    arg1: &mut Configurator, 
    arg2: coin::Coin<SUI>, 
    arg3: u64, 
    arg4: &mut tx_context::TxContext
) : coin::Coin<T>
```

- **arg0**: `&mut BondingCurve<T>` - BondingCurve Object
- **arg1**: `&mut Configurator` - Configurator Object
- **arg2**: `coin::Coin<SUI>` - SUI Coin Object
- **arg3**: `u64` - Input SUI Amount
- **arg4**: `&mut tx_context::TxContext` - Transaction context

### confirm_migration

```rust
public fun confirm_migration(
    _arg0: &AdminCap, 
    arg1: u64, 
    arg2: object::ID, 
    arg3: ascii::String, 
    arg4: object::ID, 
    arg5: u64, 
    arg6: u64
)
```

- **_arg0**: `&AdminCap` - Management Permission Object
- **arg1**: `u64` - Adapter ID
- **arg2**: `object::ID` - Object ID
- **arg3**: `ascii::String` - Token Type
- **arg4**: `object::ID` - Target Pool ID
- **arg5**: `u64` - SUI Token Balance
- **arg6**: `u64` - Other Token Balance

### list

```rust
public fun list<T>(
    arg0: &mut Configurator,
    arg1: &mut coin::TreasuryCap<T>,
    arg2: &coin::CoinMetadata<T>,
    arg3: coin::Coin<SUI>,
    arg4: option::Option<ascii::String>,
    arg5: option::Option<ascii::String>,
    arg6: option::Option<ascii::String>,
    arg7: u64,
    arg8: &mut tx_context::TxContext
) : BondingCurve<T>
```

- **arg0**: `&mut Configurator` - Configurator Object
- **arg1**: `&mut coin::TreasuryCap<T>` - Mutable Token Financial Cap Object
- **arg2**: `&coin::CoinMetadata<T>` - Token Metadata Object
- **arg3**: `coin::Coin<SUI>` - SUI Coin Object
- **arg4**: `option::Option<ascii::String>` - Twitter
- **arg5**: `option::Option<ascii::String>` - Telegram
- **arg6**: `option::Option<ascii::String>` - Website
- **arg7**: `u64` - Virtual SUI Amount
- **arg8**: `&mut tx_context::TxContext` - Transaction context

### migrate

```rust
public fun migrate<T>(
    _arg0: &AdminCap,
    arg1: &mut BondingCurve<T>,
    arg2: u64,
    arg3: &mut tx_context::TxContext
) : BondingCurve<T>
```

- **_arg0**: `&AdminCap` - Management Permission Object
- **arg1**: `&mut BondingCurve<T>` - BondingCurve Object
- **arg2**: `u64` - Migration target
- **arg3**: `&mut tx_context::TxContext` - Transaction context

### sell

```rust
public fun sell<T>(
    arg0: &mut BondingCurve<T>,
    arg1: &mut Configurator,
    arg2: coin::Coin<T>,
    arg3: u64,
    arg4: &mut tx_context::TxContext
) : coin::Coin<SUI>
```

- **arg0**: `&mut BondingCurve<T>` - BondingCurve Object
- **arg1**: `&mut Configurator` - Configurator Object
- **arg2**: `coin::Coin<T>` - Coin Object
- **arg3**: `u64` - Input Token Amount
- **arg4**: `&mut tx_context::TxContext` - Transaction context

### update_listing_fee

```rust
public fun update_listing_fee(
    _arg0: &AdminCap, 
    arg1: &mut Configurator, 
    arg2: u64
)
```

- **_arg0**: `&AdminCap` - Management Permission Object
- **arg1**: `&mut Configurator` - Configurator Object
- **arg2**: `u64` - Listing Fee

### update_migration_fee

```rust
public fun update_migration_fee(
    _arg0: &AdminCap, 
    arg1: &mut Configurator, 
    arg2: u64
)
```

- **_arg0**: `&AdminCap` - Management Permission Object
- **arg1**: `&mut Configurator` - Configurator Object
- **arg2**: `u64` - Migration Fee

### update_target_supply_threshold

```rust
public fun update_target_supply_threshold(
    _arg0: &AdminCap, 
    arg1: &mut Configurator, 
    arg2: u64
)
```

- **_arg0**: `&AdminCap` - Management Permission Object
- **arg1**: `&mut Configurator` - Configurator Object
- **arg2**: `u64` - Target supply threshold

### update_virtual_sui_liq

```rust
public fun update_virtual_sui_liq(
    _arg0: &AdminCap, 
    arg1: &mut Configurator, 
    arg2: u64
)
```

- **_arg0**: `&AdminCap` - Management Permission Object
- **arg1**: `&mut Configurator` - Configurator Object
- **arg2**: `u64` - Virtual SUI Amount

## Notes

- `buy` The function allows a user to purchase tokens with a specified SUI Amount.
- `sell` The function allows users to sell tokens back to Object and receive SUI.
- `list` The function creates a new Object and lists it on the platform.
- `migrate` The function handles migration.
- `update_listing_fee`, `update_migration_fee`, `update_target_supply_threshold`, & `update_virtual_sui_liq` Functions allow updating various configuration parameters.
***

If you're interested in having the Pump.fun smart contract access or have any doubts, please reach out to me through the following contacts:

- <a href="https://t.me/angel001000010100/">Telegram</a> 📱
- <a href="https://discordapp.com/users/1114372741672488990">Discord</a> 🎮

### If you found this helpful, don't forget to <a href="https://github.com/sinniez">follow</a> me. 🌟