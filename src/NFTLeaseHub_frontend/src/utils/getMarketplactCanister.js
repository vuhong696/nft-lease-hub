import createCanisterFromPlug from "./createCanisterFromPlug";
import canisterIds from "../../canister_ids.json"
import { idlFactory } from "../../../declarations/NFTLeaseHub_backend/NFTLeaseHub_backend.did.js"

export default async function getMarketplaceCanister () {
    const marketplaceCanisterId = canisterIds["marketplace"]["ic"];
    return await createCanisterFromPlug(marketplaceCanisterId, idlFactory);
}
