import BlindAuction from "./app.js";

const mainEl = document.getElementsByClassName("main")[0];

/// connect to metamask
document.getElementsByClassName("wallet-connect")[0].addEventListener("click", async () => {
    if(!BlindAuction.isInitialized) {
        await BlindAuction.init();
        await populateAuctions(); // populate auctions created by users
        M.toast({html: "Successfully initialized"});
    } else {
        M.toast({html: "Already initialized"});
    }
})

/// create new auction
document.getElementsByClassName("new-auction")[0].addEventListener("click", async () => {
    await BlindAuction.newAuction().then(async auctionId => {
        M.toast({html : `The auction ID is: ${auctionId}`});
    }).catch(err => {
        M.toast({html : err.message})
    })
})

/// auto-populate auctions created by user
document.addEventListener('readystatechange', async () => {
    populateAuctions();
})

async function populateAuctions() {
    const auctions = await BlindAuction.getAuctions().catch(err => M.toast({html : err.message}));
    console.log(auctions);
    console.log(BlindAuction.selectedAddress)
    const filtered = auctions.filter(auction => auction[1] == BlindAuction.selectedAddress)
    console.log(filtered);

    filtered.forEach(auction => {
        const div = document.createElement("div"); // create auction container
        let currentPhase;
        switch(auction[0]) {
            case 0 :
                currentPhase = "Initialized";
                break;
            case 1:
                currentPhase = "Bidding";
                break;
            case 2:
                currentPhase = "Reveal";
                break;
            default:
                currentPhase = "Done";
                break;
        }
        div.innerHTML = `
            <section class="auction-detail">
                <p class="flex"><span class="t">Auction ID:</span> <span class="v">${auction[2]}</span></p>
                <p class="flex"><span class="t">Created By:</span> <span class="v">${auction[1]}</span></p>
                <p class="flex"><span class="t">Phase:</span> <span class="v">${currentPhase}</span></p>
            </section>
        `;

        mainEl.append(div);
        
    })
}