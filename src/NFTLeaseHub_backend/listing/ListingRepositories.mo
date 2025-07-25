
import Hash "mo:base/Hash";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

import PageHelper "../base/PageHelper";
import TrieRepositories "../repository/TrieRepositories";
import ListingDomain "ListingDomain";
import Types "../base/Types";
import Utils "../base/Utils";

module {

    public type UserPrincipal = Types.UserPrincipal;

    public type ListingId = ListingDomain.ListingId;
    public type ListingProfile = ListingDomain.ListingProfile;

    public type DB<K, V> = TrieRepositories.TrieDB<K, V>;
    
    public type ListingPage = PageHelper.Page<ListingProfile>;
    public type ListingDB = DB<ListingId, ListingProfile>;
    public type ListingRepository = TrieRepositories.TrieRepository<ListingId, ListingProfile>;
    public type ListingDBKey = TrieRepositories.TrieDBKey<ListingId>;

    
    public func listingDBKey(key: ListingId): ListingDBKey {
        { key = key; hash = Hash.hash(Nat64.toNat(key)) }
    };

    let listingEq = ListingDomain.listingEq;

    public func newListingDB() : ListingDB {
        Trie.empty<ListingId, ListingProfile>()
    };

    public func newListingRepository() : ListingRepository{
        TrieRepositories.TrieRepository<ListingId, ListingProfile>()
    };

    
    /// Args:
   
   
    /// Returns:
   
    public func deleteListing(db: ListingDB, repository: ListingRepository, listingId: ListingId) : ListingDB {
        repository.delete(db, listingDBKey(listingId), listingEq)
    };

    
    public func findOneListingByName(db: ListingDB, repository: ListingRepository, name: Text) : ? ListingProfile {
        let listings: ListingDB = repository.findBy(db, func (uid: ListingId, up : ListingProfile): Bool { 
            up.name == name
        });

        Option.map<(Trie.Key<ListingId>, ListingProfile), ListingProfile>(Trie.nth<ListingId, ListingProfile>(listings, 0), func (kv) : ListingProfile { kv.1 })
    };

    
    public func getListing(db: ListingDB, repository: ListingRepository, id: ListingId) : ?ListingProfile {
        repository.get(db, listingDBKey(id), listingEq)
    };

    public func pageListing(db: ListingDB, repository: ListingRepository, pageSize: Nat, pageNum: Nat,
        filter: (ListingId, ListingProfile) -> Bool, sortWith: (ListingProfile, ListingProfile) -> Order.Order) : ListingPage {
        repository.page(db, pageSize, pageNum, filter, sortWith)
    };

    
    public func updateListing(db: ListingDB, repository: ListingRepository, listingProfile: ListingProfile): (ListingDB, ?ListingProfile) {
        repository.update(db, listingProfile, listingDBKey(listingProfile.id), listingEq)
    };

    
    public func saveListing(db: ListingDB, repository: ListingRepository, listingProfile: ListingProfile): ListingDB {
        updateListing(db, repository, listingProfile).0
    };

    
    public func countListingTotal(db : ListingDB, repository: ListingRepository) :  Nat {
        repository.countSize(db)
    };

    
    public func allListingIds(listingDB: ListingDB) : [ListingId] {
        Trie.toArray<ListingId, ListingProfile, ListingId>(listingDB, func (k: ListingId, _) : ListingId { k })
    };

    public func allListing(listingDB: ListingDB) : [ListingProfile] {
        Trie.toArray<ListingId, ListingProfile, ListingProfile>(listingDB, func (k: ListingId, v: ListingProfile) : ListingProfile {v})
    };
}