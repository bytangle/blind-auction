import {ethers} from "ethers";

var window : any;

const p = new ethers.providers.Web3Provider(window.ethereum, "any");
const x = new ethers.Contract("", [], p.getSigner())
p.listAccounts()