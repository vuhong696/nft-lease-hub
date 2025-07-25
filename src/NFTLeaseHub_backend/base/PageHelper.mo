
import Nat "mo:base/Nat";

module {
    public type Page<T> = {
        data : [T];
        pageSize : Nat;
        pageNum : Nat;
        totalCount: Nat;
    };

 
    public func pageToJson<T>(page: Page<T>, f: [T] -> Text) : Text {
        "{" #
            "\"pageSize\": " # Nat.toText(page.pageSize)  # ", " # 
            "\"pageNum\": " # Nat.toText(page.pageNum)  # ", " # 
            "\"totalCount\": " # Nat.toText(page.totalCount)  # ", " # 
            "\"data\" : " # f(page.data) # 
        "}"
    }
}