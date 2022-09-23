import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuctionService } from './services/auction/auction.service';



@NgModule({
  declarations: [AuctionService],
  exports : [AuctionService],
  imports: [
    CommonModule
  ]
})
export class SharedModule { }
