
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

import PageHelper "../base/PageHelper";
import TrieRepositories "../repository/TrieRepositories";
import UserDomain "UserDomain";
import Utils "../base/Utils";

module {

    public type UserPrincipal = UserDomain.UserPrincipal;
    public type UserProfile = UserDomain.UserProfile;

    public type DB<K, V> = TrieRepositories.TrieDB<K, V>;
    
    public type UserPage = PageHelper.Page<UserProfile>;
    public type UserDB = DB<UserPrincipal, UserProfile>;
    public type UserRepository = TrieRepositories.TrieRepository<UserPrincipal, UserProfile>;
    public type UserDBKey = TrieRepositories.TrieDBKey<UserPrincipal>;

    
    public func userDBKey(key: UserPrincipal): UserDBKey {
        { key = key; hash = Principal.hash(key) }
    };

    let userEq = UserDomain.userEq;
    let userHash = UserDomain.userHash;

    public func newUserDB() : UserDB {
        Trie.empty<UserPrincipal, UserProfile>()
    };

    public func newUserRepository() : UserRepository{
        TrieRepositories.TrieRepository<UserPrincipal, UserProfile>()
    };

    
    /// Args:
    
    
    /// Returns:
   
    public func deleteUser(db: UserDB, repository: UserRepository, keyOfUser: UserPrincipal) : UserDB {
        repository.delete(db, userDBKey(keyOfUser), userEq)
    };

   
    public func findOneUserByName(db: UserDB, repository: UserRepository, username: Text) : ? UserProfile {
        let users: UserDB = repository.findBy(db, func (uid: UserPrincipal, up : UserProfile): Bool { 
            up.username == username
        });

        Option.map<(Trie.Key<UserPrincipal>, UserProfile), UserProfile>(Trie.nth<UserPrincipal, UserProfile>(users, 0), func (kv) : UserProfile { kv.1 })
    };

  
    public func getUser(db: UserDB, repository: UserRepository, owner: UserPrincipal) : ?UserProfile {
        repository.get(db, userDBKey(owner), userEq)
    };

    public func pageUser(db: UserDB, repository: UserRepository, pageSize: Nat, pageNum: Nat,
        filter: (UserPrincipal, UserProfile) -> Bool, sortWith: (UserProfile, UserProfile) -> Order.Order) : UserPage {
        repository.page(db, pageSize, pageNum, filter, sortWith)
    };

 
    public func updateUser(db: UserDB, repository: UserRepository, userProfile: UserProfile): (UserDB, ?UserProfile) {
        repository.update(db, userProfile, userDBKey(userProfile.owner), userEq)
    };

 
    public func saveUser(db: UserDB, repository: UserRepository, userProfile: UserProfile): UserDB {
        updateUser(db, repository, userProfile).0
    };

 
    public func countUserTotal(db : UserDB, repository: UserRepository) :  Nat {
        repository.countSize(db)
    };

 
    public func allUserPrincipals(userDB: UserDB) : [UserPrincipal] {
        Trie.toArray<UserPrincipal, UserProfile, UserPrincipal>(userDB, func (k: UserPrincipal, _) : UserPrincipal { k })
    };

}