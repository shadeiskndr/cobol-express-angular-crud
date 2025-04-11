import { Component, Input } from '@angular/core';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

@Component({
  selector: 'app-loading-spinner',
  standalone: true,
  imports: [MatProgressSpinnerModule],
  template: `
    <div
      class="spinner-container"
      [style.height]="fullHeight ? '100%' : 'auto'"
    >
      <mat-spinner [diameter]="diameter"></mat-spinner>
    </div>
  `,
  styles: `
    .spinner-container {
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 20px;
      min-height: 100px;
    }
  `,
})
export class LoadingSpinnerComponent {
  @Input() diameter: number = 40;
  @Input() fullHeight: boolean = false;
}
