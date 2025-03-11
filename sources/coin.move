/// Module: pumpfun
module pumpfun::coin {
    use sui::coin::{Self,TreasuryCap,Coin};
    use std::ascii::{Self};
    use std::string::{String};

    public struct COIN has drop {}

    fun init(witness: COIN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<COIN>(
            witness, 9, b"coin", b"Coin", b"", option::none(), ctx);

        transfer::public_transfer(metadata, tx_context::sender(ctx));
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));

    }

    public fun set_coin_metadata_info(
        name: String,
        symbol: vector<u8>,
        description: String,
        icon_url: vector<u8>,
        _treasury: &coin::TreasuryCap<COIN>, 
        metadata: &mut coin::CoinMetadata<COIN>
    ) {
        let icon_url = ascii::string(icon_url);
        let symbol = ascii::string(symbol);
        coin::update_name(_treasury,metadata,name);
        coin::update_symbol(_treasury,metadata,symbol);
        coin::update_description(_treasury,metadata,description);
        coin::update_icon_url(_treasury,metadata,icon_url);
    }
    
    public entry fun mint_transfer_bouding_curve(
        treasury_cap: &mut TreasuryCap<COIN>,recepient:address,amount: u64, ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recepient, ctx)
    }

    /// Manager can burn coins
    public entry fun burn(treasury_cap: &mut TreasuryCap<COIN>, coin: Coin<COIN>) {
        coin::burn(treasury_cap, coin);
    }    
}