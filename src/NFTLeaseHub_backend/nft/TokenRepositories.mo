
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

import PageHelper "../base/PageHelper";
import TrieRepositories "../repository/TrieRepositories";
import TokenDomain "TokenDomain";
import Types "../base/Types";
import Utils "../base/Utils";

module {

    public type UserPrincipal = Types.UserPrincipal;

    public type TokenId = TokenDomain.TokenId;
    public type TokenProfile = TokenDomain.TokenProfile;

    public type DB<K, V> = TrieRepositories.TrieDB<K, V>;
    
    public type TokenPage = PageHelper.Page<TokenProfile>;
    public type TokenDB = DB<TokenId, TokenProfile>;
    public type TokenRepository = TrieRepositories.TrieRepository<TokenId, TokenProfile>;
    public type TokenDBKey = TrieRepositories.TrieDBKey<TokenId>;

    

   
    public func tokenDBKey(key: TokenId): TokenDBKey {
        { key = key; hash = Hash.hash(key) }
    };

    let tokenEq = TokenDomain.tokenEq;

    public func newTokenDB() : TokenDB {
        Trie.empty<TokenId, TokenProfile>()
    };

    public func newTokenRepository() : TokenRepository{
        TrieRepositories.TrieRepository<TokenId, TokenProfile>()
    };

   
    /// Args:
  
  
    /// Returns:
  
    public func deleteToken(db: TokenDB, repository: TokenRepository, tokenId: TokenId) : TokenDB {
        repository.delete(db, tokenDBKey(tokenId), tokenEq)
    };

   
    public func findOneTokenByName(db: TokenDB, repository: TokenRepository, name: Text) : ? TokenProfile {
        let tokens: TokenDB = repository.findBy(db, func (uid: TokenId, up : TokenProfile): Bool { 
            up.name == name
        });

        Option.map<(Trie.Key<TokenId>, TokenProfile), TokenProfile>(Trie.nth<TokenId, TokenProfile>(tokens, 0), func (kv) : TokenProfile { kv.1 })
    };

   
    public func getToken(db: TokenDB, repository: TokenRepository, id: TokenId) : ?TokenProfile {
        repository.get(db, tokenDBKey(id), tokenEq)
    };

    public func pageToken(db: TokenDB, repository: TokenRepository, pageSize: Nat, pageNum: Nat,
        filter: (TokenId, TokenProfile) -> Bool, sortWith: (TokenProfile, TokenProfile) -> Order.Order) : TokenPage {
        repository.page(db, pageSize, pageNum, filter, sortWith)
    };

   
    public func updateToken(db: TokenDB, repository: TokenRepository, tokenProfile: TokenProfile): (TokenDB, ?TokenProfile) {
        repository.update(db, tokenProfile, tokenDBKey(tokenProfile.id), tokenEq)
    };

   
    public func saveToken(db: TokenDB, repository: TokenRepository, tokenProfile: TokenProfile): TokenDB {
        updateToken(db, repository, tokenProfile).0
    };

   
    public func countTokenTotal(db : TokenDB, repository: TokenRepository) :  Nat {
        repository.countSize(db)
    };

   
    public func allTokenIds(tokenDB: TokenDB) : [TokenId] {
        Trie.toArray<TokenId, TokenProfile, TokenId>(tokenDB, func (k: TokenId, _) : TokenId { k })
    };

}