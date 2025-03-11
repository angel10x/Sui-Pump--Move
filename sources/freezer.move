module pumpfun::freezer {

    public struct Ice<T0: store + key> has key {
        id: UID,
        obj: T0,
    }

    #[allow(lint(freeze_wrapped))]
    public entry fun freeze_object<T0: store + key>(arg0: T0, arg1: &mut tx_context::TxContext) {
        let v0 = Ice<T0>{
            id  : object::new(arg1),
            obj : arg0,
        };
        transfer::freeze_object<Ice<T0>>(v0);
    }

}