
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Arrays "mo:base/Array";
import Blob "mo:base/Blob";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import List "mo:base/List";

import Account "./Account/Account";
import Dip721 "../NFTLeaseHub_backend/canisters/dip721.did";
import LendDomain "lend/LendDomain";
import LendRepositories "lend/LendRepositories";
import ListingDomain "listing/ListingDomain";
import ListingRepositories "listing/ListingRepositories";
import Sharing "../NFTLeaseHub_backend/canisters/sharing.did";
import TokenDomain "nft/TokenDomain";
import Types "base/Types";
import UserDomain "user/UserDomain";
import UserRepositories "user/UserRepositories";
import Voice "./voice/Voice";
import Ledger "./ledger/ledger.public.did";
import PageHelper "./base/PageHelper";
import Utils "./base/Utils";

shared(msg) actor class NFTLeaseHub_backend() = self {
    let sharingCanisterId = "jpabj-zyaaa-aaaah-qaiya-cai";
    let sharingCanister: Sharing.NFToken = actor(sharingCanisterId);

    let ledgerCanisterId = "ryjl3-tyaaa-aaaaa-aaaba-cai";
    let ledgerCanister: Ledger.Self = actor(ledgerCanisterId);

    let nftCansiterId = "my55u-diaaa-aaaah-qcoaa-cai"; 
    let nftCansiter:Dip721.NFToken = actor(nftCansiterId);

    public type Result<X, Y> = Types.Result<X, Y>;

    public type UserProfile = UserDomain.UserProfile;

    public type ListingCreateCommand = ListingDomain.ListingCreateCommand;
    public type ListingIdCommand = ListingDomain.ListingIdCommand;
    public type ListingPageQuery = ListingDomain.ListingPageQuery;
    public type ListingPage = ListingRepositories.ListingPage;

    public type LendCreateCommand = LendDomain.LendCreateCommand;

    public type LendIdCommand = LendDomain.LendIdCommand;

    public type Error = Types.Error;

    stable var idGenerator : Nat64 = 10001;

    let owner = msg.caller;

    stable var userDB = UserRepositories.newUserDB();
    let userRepository = UserRepositories.newUserRepository();

    stable var listingDB = ListingRepositories.newListingDB();
    let listingRepository = ListingRepositories.newListingRepository();

    stable var lendDB = LendRepositories.newLendDB();
    let lendRepository = LendRepositories.newLendRepository();

    stable var  nftCansterId = "";

    stable var sharingNftCanisterId = "";

    public query func healthcheck() : async Bool { true };

    stable var canisters: [Principal] = [];

    stable var voiceStableDb : Voice.StableDB = Voice.stableDbInitValue();
    let voiceStore   = Voice.Store();

    public shared(msg) func registerUser() : async Bool {
        let caller = msg.caller;
        switch (UserRepositories.getUser(userDB, userRepository, caller)) {
            case (?u) false;
            case (null) {
                let user = UserDomain.newUser(getIdAndIncrementOne(), caller, "", timeNow_());
                userDB := UserRepositories.saveUser(userDB, userRepository, user);
                true
            }
        }
    };

    public query(msg) func getSelf() : async ?UserProfile {
        let caller = msg.caller;
        UserRepositories.getUser(userDB, userRepository, caller)
    };

    public query(msg) func getUser(user: Principal) : async ?UserProfile {
        UserRepositories.getUser(userDB, userRepository, user)
    };
    
    public query func getCanisterPrincipal(): async Text {
        Principal.toText(Principal.fromActor(self));
    };

    public shared(msg) func preListingNFT(cmd: ListingCreateCommand) : async Result<Nat64, Error> {
        let caller = msg.caller;
        let id = getIdAndIncrementOne();

        let tokenInfo: Dip721.TokenInfoExt =
        switch(await nftCansiter.getTokenInfo(cmd.nftId)) {
            case(#Ok(tokenInfo)) {
                switch(tokenInfo.metadata){
                    case(null){
                        return #Err(#unauthorized);
                    };
                    case(_){};
                };
                tokenInfo;
            };
            case(_) {
                return #Err(#notFound);
            }
        };
        if(Principal.notEqual(caller, tokenInfo.owner)) {
            return #Err(#unauthorized);
        };

        let listingProfile = ListingDomain.createProfile(cmd, id, caller, timeNow_(), tokenInfo, null);
        listingDB := ListingRepositories.saveListing(listingDB, listingRepository, listingProfile);
        #Ok(id)
    };

    public shared(msg) func listingNFT(cmd: ListingIdCommand) : async Result<Nat, Error> {
        let caller = msg.caller;
        switch (ListingRepositories.getListing(listingDB, listingRepository, cmd.id)) {
            case (?l) {

                let nftOwner : Principal = switch(await nftCansiter.ownerOf(l.nftId)) {
                    case (#Ok(owner)) {
                        owner;
                    };
                    case (_) {
                        return #Err(#notFound);
                    };
                };
                if(Principal.notEqual(nftOwner, Principal.fromActor(self))) {
                    return #Err(#unauthorized);
                };
                if(Principal.notEqual(caller, l.owner)) { 
                    return #Err(#unauthorized);
                };
                

                let tokenMetadata = switch(await nftCansiter.getTokenInfo(l.nftId)){
                    case(#Ok(tokenInfo)) { 
                        switch(tokenInfo.metadata) {
                            case(?metadata){
                                metadata;
                            };
                            case(_){
                                Prelude.unreachable();//
                            };
                        }
                    };
                    case(_) {
                        return #Err(#notFound);
                    };
                };
                
                let listingId: Sharing.Attribute = {
                    key = "listingId";
                    value = Nat64.toText(l.id);
                };
                let nftType: Sharing.Attribute = {
                    key = "type";
                    value = "wNFT";
                };
                let name: Sharing.Attribute = {
                    key = "name";
                    value = l.name;
                };
                let desc: Sharing.Attribute = {
                    key = "desc";
                    value = l.desc;
                };
                let originalNftId: Sharing.Attribute = {
                    key = "originalNft";
                    value = Nat.toText(l.nftId);
                };
                let canisterId : Sharing.Attribute = {
                    key = "canisterId";
                    value = l.canisterId;
                };
     
                let attributeBuffer = Buffer.Buffer< Sharing.Attribute>(5);                               
                attributeBuffer.add(nftType);
                attributeBuffer.add(name);
                attributeBuffer.add(desc);  
                attributeBuffer.add(originalNftId);  
                attributeBuffer.add(canisterId);  
                attributeBuffer.add(listingId);                                

                let wTokenMetadata: Sharing.TokenMetadata = {
                    filetype = tokenMetadata.filetype;
                    attributes = attributeBuffer.toArray();
                    location = tokenMetadata.location;
                };
                let wTokenId = switch(await sharingCanister.mint(caller, ?wTokenMetadata)){
                    case(#Ok((wTokenId, _))){
                        wTokenId;
                    };
                    case(_){
                        return #Err(#mintFailed);
                    };
                };
                let listingProfile: ListingDomain.ListingProfile = ListingDomain.updateListingStaked(l, ?wTokenId);
                listingDB := ListingRepositories.updateListing(listingDB, listingRepository, listingProfile).0;
                return #Ok(wTokenId);
            };
            case (null) {
                return #Err(#notFound);
            }
        }
    };

    public shared(msg) func redeem(cmd: ListingIdCommand) : async Result<Nat64, Error> {
        let caller = msg.caller;
        switch (ListingRepositories.getListing(listingDB, listingRepository, cmd.id)) {
            case (?l) {
                let redeemNftId = switch(l.redeemNftId){
                    case(?redeemNftId) {redeemNftId};
                    case(null) {
                        return #Err(#notFound);
                    };
                };
                let redeemOwner = switch(await sharingCanister.ownerOf(redeemNftId)){
                    case(#Ok(owner)){
                        if(caller != owner) {
                            return #Err(#unauthorized);
                        };
                        owner
                    };
                    case(_){return #Err(#notFound)};
                };
                switch(await sharingCanister.burn(redeemNftId)) {
                    case(#Ok(txId)){};
                    case(#Err(err)){
                        let errMsg: Text = switch(err){
                            case (#Unauthorized) {"Unauthorized"};
                            case (#TokenNotExist) {"TokenNotExist"};
                            case (#InvalidOperator) {"InvalidOperator"};
                            case (#UserNotExist) {"UserNotExist"};
                        };
                        return #Err(#burnFailed(errMsg))
                    };
                };
                let nftCansiter : Dip721.NFToken = actor(l.canisterId); 
                switch(await nftCansiter.transfer(redeemOwner, l.nftId)){
                    case(#Ok(txId)){

                       let listingProfile: ListingDomain.ListingProfile = ListingDomain.updateListingStatus(l, #Redeemed);
                       listingDB := ListingRepositories.updateListing(listingDB, listingRepository, listingProfile).0; 
                        return #Ok(l.id);
                    };
                    case(#Err(err)){
                        let errMsg: Text = switch(err){
                            case (#Unauthorized) {"Unauthorized"};
                            case (#TokenNotExist) {"TokenNotExist"};
                            case (#InvalidOperator) {"InvalidOperator"};
                            case (#UserNotExist) {"UserNotExist"};
                        };
                        return #Err(#transferFailed(errMsg))
                    };
                };
            };
            case (null) {
                return #Err(#notFound);
            };
        };
    };
    
    func isRenting(listId: Nat64): Bool{
        LendRepositories.some(lendDB, lendRepository, func (k: LendDomain.LendId, v: LendDomain.LendProfile) {
            v.listingId == listId and validLend(v);
        });
    };
    
    func validLend(lend: LendDomain.LendProfile) : Bool{
        timeNow_() < lend.end 
        and lend.status == #Enable
    };

    public query(msg)  func pageListings(q: ListingPageQuery) : async ListingPage {
        let user : ?Principal = q.user;
        let pageSize = q.pageSize;
        let pageNum = q.pageNum;
        let status = q.status;

        ListingRepositories.pageListing(listingDB, listingRepository, pageSize, pageNum, func (id, profile) : Bool {
            switch(user) {
                case(?user) {
                    return ListingDomain.listingUserMatches(profile, user) and status == profile.status;
                };
                case(null) {
                    return status == profile.status;
                };
            }
            
        }, ListingDomain.listingOrderUpdateTimeDesc)
    };

    public query(msg) func allListing() : async [ListingDomain.ListingProfile] {
        ListingRepositories.allListing(listingDB);
    };

    public shared(msg) func preLendNFT(cmd: LendCreateCommand) : async Result<LendDomain.LendProfile, Error> {
        let caller = msg.caller;
        let listingId = cmd.listingId;

        switch (ListingRepositories.getListing(listingDB, listingRepository, listingId)) {
            case (?listing) {
                if (listing.status != #Enable) {
                    return #Err(#listingNotEnable);
                };
                if((cmd.end - cmd.start)/3600 < 1){
                    return #Err(#parameterErr("rent time too short."));
                };

                if(cmd.end > listing.availableUtil) {
                    return #Err(#parameterErr("Out of available time"));
                };
                let lendId = getIdAndIncrementOne();
                let now = timeNow_();
               
                let accountIdentifier = Account.accountIdentifier(Principal.fromActor(self), Account.defaultSubaccount());
                
                
                let amount: Nat64 = Nat64.fromNat((cmd.end - cmd.start) * listing.price.decimals /3600); 
                let lendOrder = LendDomain.createProfile(listing.id, lendId, caller, listing.owner ,now, cmd.start, cmd.end, accountIdentifier, amount, listing.web);
                lendDB := LendRepositories.saveLend(lendDB, lendRepository, lendOrder);
                #Ok(lendOrder);
            };
            case (null) #Err(#listingNotFound);
        }
    };
    
    func rentTimeAvailable(listId: Nat64, start: Nat, end: Nat) : Bool{ 
        let lendList: [LendDomain.LendProfile] = LendRepositories.getLendByListId(lendDB, lendRepository, listId);
        for(l in lendList.vals()) {
            if(isOverlap(start, end, l.start, l.end)){
                return false;
            };
        };
        return true;
    };

    func isOverlap(a1: Nat, a2: Nat, b1: Nat, b2: Nat): Bool{
        let begin: Nat = Nat.max(a1, b1);
        let end : Nat = Nat.min(a2, b2);
        end - begin >= 0;
    };

    func myAccountId() : Account.AccountIdentifier {
        Account.accountIdentifier(Principal.fromActor(self), Account.defaultSubaccount())
    };

    public query(msg) func accountId(): async Blob {
        return Account.accountIdentifier(Principal.fromActor(self), Account.defaultSubaccount());
    };

    public  func canisterBalance() : async Ledger.Tokens {
        await ledgerCanister.account_balance({ account =  Account.accountIdentifier(Principal.fromActor(self), Account.defaultSubaccount()) })
    };

    public query func getLend(cmd: LendIdCommand) : async Result<LendDomain.LendProfile, Error> {
           return switch(LendRepositories.getLend(lendDB, lendRepository, cmd.id)){
            case(?lend) {
                return #Ok(lend);
            };
            case(null) {
                return #Err(#notFound);
            };
        };
    };

    public query func pageUserLend(user: Principal, pageSize: Nat, pageNum: Nat): async LendRepositories.LendPage {        
        let filter : (Nat64, LendDomain.LendProfile) -> Bool = func (id: Nat64, lend: LendDomain.LendProfile) {
            if(lend.owner == user) {
                return true;
            };
            return false;
        };
        return LendRepositories.pageLend(lendDB, lendRepository, pageSize, pageNum, filter, LendDomain.lendOrderUpdateTimeDesc); 
    };
    public query func pageEnableLend(pageSize: Nat, pageNum: Nat) : async LendRepositories.LendPage{
        let filter : (Nat64, LendDomain.LendProfile) -> Bool = func (id: Nat64, lend: LendDomain.LendProfile) {
            switch(lend.status){
                case(#Enable) {
                    true;
                };
                case(_) {
                    false;
                };
            };
        };
        return LendRepositories.pageLend(lendDB, lendRepository, pageSize, pageNum, filter, LendDomain.lendOrderUpdateTimeDesc);
    };

    public shared(msg) func notify(cmd: LendIdCommand, blockIndex: Nat64) : async Result<Nat64, Error> {
        let caller = msg.caller;
        let lendId = cmd.id;

        switch(LendRepositories.getLend(lendDB, lendRepository, lendId)) {
            case(?lend) {
                let getBlockArg : Ledger.GetBlocksArgs = {
                    start = blockIndex;
                    length = 1;
                };
                let queryBlockResponse : Ledger.QueryBlocksResponse = await ledgerCanister.query_blocks(getBlockArg);

                let block : Ledger.Block = queryBlockResponse.blocks[0];
                let transaction : Ledger.Transaction = block.transaction;
                let memo : Ledger.Memo = transaction.memo;

                switch(transaction.operation: ?Ledger.Operation) {
                    case(?o) {                
                        switch(o){
                            case(#Burn(_)){};
                            case(#Mint(_)){};
                            case(#Transfer(transfer)){
                                type Transfer = {
                                    from : Ledger.AccountIdentifier;
                                    to : Ledger.AccountIdentifier;
                                    amount : Ledger.Tokens;
                                    fee : Ledger.Tokens;
                                };
                        
                               if(not Blob.equal(transfer.to, Account.accountIdentifier(Principal.fromActor(self), Account.defaultSubaccount()))) {
                                   return #Err(#parameterErr("the target account error."));
                               };
                               if(not Nat64.equal(transfer.amount.e8s, lend.amount)) {
                                   return #Err(#parameterErr("amount error."));
                               };
                           };   
                      };
                    };
                    case(null) {
                        return #Err(#parameterErr("the operation is null, inn query_blocks"));
                    };
                };
                let l: ListingDomain.ListingProfile = switch (ListingRepositories.getListing(listingDB, listingRepository, lend.listingId)) {
                    case (?listing) {
                        listing;
                    };
                    case (null) {
                        return #Err(#listingNotFound);
                    }
                };
                let nftCansiter : Dip721.NFToken = actor(l.canisterId); 
                let tokenMetadata = switch(await nftCansiter.getTokenInfo(l.nftId)){
                    case(#Ok(tokenInfo)) { 
                        switch(tokenInfo.metadata) {
                            case(?metadata){
                                metadata;
                            };
                            case(_){
                                Prelude.unreachable();
                            };
                        }
                    };
                    case(_) {
                        return #Err(#notFound);
                    };
                };
                let nftType: Sharing.Attribute = {
                    key = "type";
                    value = "uNFT";
                };
                let start: Sharing.Attribute = {
                    key = "start";
                    value = Nat.toText(lend.start);
                };
                let end: Sharing.Attribute = {
                    key = "end";
                    value = Nat.toText(lend.start);
                };
                let nftOwner: Sharing.Attribute = {
                    key = "nftOwner";
                    value = Principal.toText(lend.nftOwner);
                };
                let amount: Sharing.Attribute = {
                    key = "amount";
                    value = Nat64.toText(lend.amount);
                };      
                let attributeBuffer = Buffer.Buffer< Sharing.Attribute>(5);                               
                attributeBuffer.add(nftType);
                attributeBuffer.add(start);
                attributeBuffer.add(end);                                
                attributeBuffer.add(nftOwner);
                attributeBuffer.add(amount);

                let wTokenMetadata: Sharing.TokenMetadata = {
                    filetype = tokenMetadata.filetype;
                    attributes = attributeBuffer.toArray();
                    location = tokenMetadata.location;
                };
                let uTokenId = switch(await sharingCanister.mint(caller, ?wTokenMetadata)){
                    case(#Ok((wTokenId, _))){
                            wTokenId;
                    };
                    case(_){
                        return #Err(#mintFailed);
                    };
                };
                    
               
                let transferRentArgs: Ledger.TransferArgs = {
                    to = Account.accountIdentifier(lend.nftOwner, Account.defaultSubaccount());
                    fee = {e8s=10000};
                    memo = lend.id;
                    from_subaccount = null;
                    created_at_time = ?{timestamp_nanos = Nat64.fromNat(Int.abs(timeNow_()))};
                    amount = {e8s = lend.amount * 9 / 10};
                };

                let transferRentRes:{ #Ok : Ledger.BlockIndex; #Err : Ledger.TransferError } = await ledgerCanister.transfer(transferRentArgs);
                switch(transferRentRes){
                    case(#Ok(blockIndex)){
                    };
                    case(#Err(transferErr)){
                        let errMsg: Text = switch(transferErr) {
                        case(#TxTooOld(_)){"TxTooOld in paid the rent"};
                        case(#BadFee(_)){"BadFee in paid the rent"};
                        case(#TxDuplicate(_)){"TxDuplicate in paid the rent"};
                        case(#TxCreatedInFuture(_)){"TxCreatedInFuture in paid the rent"};
                        case(#InsufficientFunds(_)){"InsufficientFunds in paid the rent"};
                    };
                            
                    return #Err(#transferFailed(errMsg));
                    };
                };

                let lendForUpdate : LendDomain.LendProfile = {
                    id = lend.id;
                    listingId = lend.listingId;
                    owner = lend.owner;
                    nftOwner = lend.nftOwner;
                    status = #Enable;
                    createdAt = lend.createdAt;
                    updatedAt = timeNow_();
                    start = lend.start;
                    end = lend.end;
                    accountIdentifier = lend.accountIdentifier;
                    amount = lend.amount;
                    uNFTId = ?uTokenId;
                    web = lend.web;
                };
                lendDB := LendRepositories.updateLend(lendDB, lendRepository, lendForUpdate).0;
                return #Ok(lend.id);
            };
            case(null) {
                return #Err(#notFound);
            };
        };
    };

    
    public shared(msg) func addNFTCansiter(canisterId: Principal) : async Bool {
        func f(p: Principal) : Bool {
            Principal.equal(p, canisterId)
        };
        switch (Array.find(canisters, f)) {
            case (?_) true;
            case null {
                canisters := Array.append<Principal>(canisters, [canisterId]);
                true
            }
        }
    };

    public shared(msg) func setNftCansterId(canisterId: Text) : async Result<Bool, Error> {
        let caller = msg.caller;
        if (caller == owner) {
            nftCansterId := canisterId;
            #Ok(true)
        } else {
            #Err(#unauthorized)
        }
        
    };

    public shared(msg) func setShareNftCansterId(canisterId: Text) : async Result<Bool, Error> {
        let caller = msg.caller;
        if (caller == owner) {
            sharingNftCanisterId := canisterId;
            #Ok(true)
        } else {
            #Err(#unauthorized)
        }
        
    };

    public query func getNFTCansiters() : async [Principal] {
        canisters
    };

    public query func getNftCansterId() : async Text {
        nftCansterId
    };

    public query func getSharingNftCansterId() : async Text {
        sharingNftCanisterId
    };

    func getIdAndIncrementOne() : Nat64 {
        let id = idGenerator;
        idGenerator += 1;
        id
    };
    
    func timeNow_() : Int {
        Time.now()
    };


    system func preupgrade() {
       voiceStableDb := voiceStore.preUpgrade();
    };

    system func postupgrade() {
        voiceStore.postUpgrade(voiceStableDb);
    };

};
