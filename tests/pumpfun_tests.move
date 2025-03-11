#[test_only]
module pumpfun::pumpfun_tests {
    // uncomment this line to import the module
    // use pumpfun::pumpfun;

    const ENotImplemented: u64 = 0;

    #[test]
    fun test_pumpfun() {
        // pass
    }

    #[test, expected_failure(abort_code = ::pumpfun::pumpfun_tests::ENotImplemented)]
    fun test_pumpfun_fail() {
        abort ENotImplemented
    }
}