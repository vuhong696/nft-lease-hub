
import Hash "mo:base/Hash";
import Nat64"mo:base/Nat64";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

module {

    public type Property<K, V> = {
        key: K;
        value: V;
    };

    public type DeleteCommand = {
        id: Id;
    };

    public type DetailQuery = {
        id: Id;
    };

    public type PageQuery = {
        pageSize: Nat;
        pageNum: Nat;
    };

    public type Id = Nat64;

    public type RichText = {
        format: Text;
        content: Text;
    };

    public func richTextToJson(rt: RichText) : Text {
         "{\"content\": \"" # rt.content # "\", \"format\": \"" # rt.format # "\"}"
    };

    public type Timestamp = Int;
    
    public type UserPrincipal = Principal;

    public let idEq = Nat64.equal;
    public let idHash = Hash.hash;

    public let userEq = Principal.equal;
    public let userHash = Principal.hash;

    public type IdOwner = {
        id: Id;
        owner: UserPrincipal;
    };
    
    
    public type Error = {
        #idDuplicated;  
        #notFound;      
        #alreadyExisted;
        #unauthorized;  
        #unknownError;
        #listingNotEnable; 
        #listingNotFound;
        #mintFailed;   
        #renting; 
        #burnFailed: Text;
        #transferFailed: Text;
        #listingLocked;
        #parameterErr: Text;
        #understock;
    };

    public type ApiError = {
        #Unauthorized;
        #InvalidTokenId;
        #ZeroAddress;
        #Other;
    };

    public type Result<S, E> = {
        #Ok : S;
        #Err : E;
    };
}
