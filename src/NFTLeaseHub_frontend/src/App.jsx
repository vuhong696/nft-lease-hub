import React from "react"
import AppContext from "./AppContext"

import { Outlet } from "react-router-dom"
import TopNav from "./component/TopNav"
import cansiterIds from "../canister_ids.json"
import { idlFactory as idlFactoryMarketplace } from "../../declarations/NFTLeaseHub_backend/NFTLeaseHub_backend.did.js"
import { idlFactory as idlFactoryRent } from "../../declarations/sharing/sharing.did.js"
import { idlFactory as idlFactoryDip721 } from "../../declarations/dip721/dip721.did.js"

import { Buffer } from "buffer";
     window.Buffer = Buffer;

function App () {
  let whitelist = [cansiterIds["marketplace"]["ic"], cansiterIds["dip721"]["ic"], cansiterIds["sharing"]["ic"]];
  let host = "https://mainnet.dfinity.network";

  const [connected, setConnected] = React.useState(false)
  const [marketplace, setMarketplace] = React.useState(null);
  const [sharing, setSharing] = React.useState(null);
  const [dip721, setDip721] = React.useState(null);

  const connect = async () => {
    try {
      let publicKey = await window.ic.plug.requestConnect({ whitelist, host });
      setConnected(true);
      return publicKey;
    } catch (error) {
      setConnected(false);
      return null;
    }
  }
  async function initMarketplace () {
    if (!connected) {
      if (!await connect()) {
        setMarketplace(null)
        return null;
      }
    }
    if (!marketplace) {
      try {
        let res = await window.ic.plug.createActor({
          canisterId: cansiterIds["marketplace"]["ic"],
          interfaceFactory: idlFactoryMarketplace,
        })
        setMarketplace(res);
        return res;
      } catch (error) {
        return null;
      }
    }
    return marketplace;
  }

  async function initSharing () {
    if (!connected) {
      if (!await connect()) {
        setSharing(null)
        return null;
      }
    }
    if (!sharing) {
      try {
        let res = await window.ic.plug.createActor({
          canisterId: cansiterIds["sharing"]["ic"],
          interfaceFactory: idlFactoryRent,
        })
        setSharing(res);
        return res;
      } catch (error) {
        return null;
      }
    }
    return marketplace;
  }


  async function initDip721 () {
    if (!connected) {
      if (!await connect()) {
        setDip721(null)
        return null;
      }
    }
    if (!dip721) {
      try {
        let res = await window.ic.plug.createActor({
          canisterId: cansiterIds["dip721"]["ic"],
          interfaceFactory: idlFactoryDip721,
        })
        console.log("dip721 is: " + JSON.stringify(res))
        setDip721(res);
        return res;
      } catch (error) {
        console.log("create plug actor error")
      }
    }
    return dip721;
  }




  return (
    <AppContext.Provider
      value={{ connect, connected, setConnected, marketplace, setMarketplace, sharing, setSharing, dip721, setDip721, initMarketplace, initSharing, initDip721, cansiterIds }}
    >
      <div className="lg:container flex flex-col flex-nowrap mx-auto">
        <TopNav></TopNav>
        <div className="min-h-800">
          <Outlet></Outlet>
        </div>
      </div>
    </AppContext.Provider>
  )
}

export { App, AppContext }
