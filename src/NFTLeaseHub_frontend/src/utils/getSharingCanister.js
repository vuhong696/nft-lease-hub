import createCanister from "./createCanisterFromPlug";
import canisterIds from "../../canister_ids.json"
import { idlFactory } from "../../../declarations/sharing/sharing.did.js"

export default async function getSharingCanister () {
    const sharingId = canisterIds["sharing"]["ic"];
    return await createCanister(sharingId, idlFactory);
}
