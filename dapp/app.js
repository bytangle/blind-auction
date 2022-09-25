import artifacts from "./assets/BlindAuction.json" assert {type: "json"};
//import ethers from "ethers";

export default class BlindAuction {
    static provider;
    static signer;
    static contract_r_w;
    static contract_r;
    static isInitialized = false;
    static contractAddr = "0x745F5e007056dAcFCdB3fD4009DB3D1FA1180865";
    static selectedAddress;

    static async init() {

        if(typeof window.ethereum == 'undefined') {
            throw new Error("Metamask not installed or supported");
        }

        this.provider = new ethers.providers.Web3Provider(window.ethereum, "any");

        await this.provider.send("eth_requestAccounts", []);
        const accts = await this.provider.listAccounts()
        this.selectedAddress = accts[0];

        this.signer = await this.provider.getSigner(
            accts[0]
        );

        console.log("Signer: ", await this.signer.getAddress());

        this.contract_r = new ethers.Contract(this.contractAddr, artifacts.abi, this.provider);
        this.contract_r_w = await this.contract_r.connect(this.signer);

        console.log("Contract signer: ", await this.contract_r_w.signer.getBalance());

        this.isInitialized = true;
    }

    static async newAuction() {
        this.#ensureInitialized();
        
        return await this.contract_r_w.newAuction().then(async trxResp => {
            console.log(trxResp);
            return trxResp.wait().then(receipt => {
                console.log(receipt);
                return receipt.events[0].args.auctionId;
            })
        })

    }

    static async getAuctions() {
        this.#ensureInitialized()

        const auctions = await this.contract_r.getAuctions();
        return auctions
    }

    static #ensureInitialized() {
        if(!this.isInitialized) throw new Error("Dapp not initialized");
    }
}