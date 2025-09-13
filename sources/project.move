module MyModule::PaymentGateway {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a merchant's payment gateway account
    struct MerchantAccount has store, key {
        total_received: u64,    // Total payments received by merchant
        transaction_count: u64, // Number of transactions processed
        is_active: bool,        // Whether the merchant account is active
    }

    /// Struct representing a payment transaction
    struct PaymentRecord has store, key {
        amount: u64,           // Payment amount
        merchant: address,     // Merchant receiving payment
        timestamp: u64,        // When payment was made
        transaction_id: u64,   // Unique transaction identifier
    }

    /// Function to register a new merchant account
    public fun register_merchant(merchant: &signer) {
        let merchant_account = MerchantAccount {
            total_received: 0,
            transaction_count: 0,
            is_active: true,
        };
        move_to(merchant, merchant_account);
    }

    /// Function to process a crypto payment from customer to merchant
    public fun process_payment(
        customer: &signer, 
        merchant_address: address, 
        amount: u64
    ) acquires MerchantAccount {
        // Get merchant account and update statistics
        let merchant_account = borrow_global_mut<MerchantAccount>(merchant_address);
        assert!(merchant_account.is_active, 1); // Ensure merchant is active
        
        // Transfer payment from customer to merchant
        let payment = coin::withdraw<AptosCoin>(customer, amount);
        coin::deposit<AptosCoin>(merchant_address, payment);
        
        // Update merchant account statistics
        merchant_account.total_received = merchant_account.total_received + amount;
        merchant_account.transaction_count = merchant_account.transaction_count + 1;
        
        // Create payment record for customer
        let payment_record = PaymentRecord {
            amount,
            merchant: merchant_address,
            timestamp: timestamp::now_seconds(),
            transaction_id: merchant_account.transaction_count,
        };
        move_to(customer, payment_record);
    }
}