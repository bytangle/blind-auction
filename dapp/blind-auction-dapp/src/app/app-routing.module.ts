import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AppComponent } from './app.component';
import { MainRoutingModule } from './modules/main/main-routine.module';

const routes: Routes = [
  {path : "", component : AppComponent}
];

@NgModule({
  imports: [MainRoutingModule, RouterModule.forRoot(routes)],
  exports: [MainRoutingModule, RouterModule]
})
export class AppRoutingModule { }
