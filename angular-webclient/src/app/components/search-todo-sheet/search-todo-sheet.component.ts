import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MatBottomSheetRef } from '@angular/material/bottom-sheet';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatListModule } from '@angular/material/list'; // Often used in bottom sheets
import { MatIconModule } from '@angular/material/icon';

export interface SearchCriteria {
  status?: string;
  minTime?: number | null;
  maxTime?: number | null;
}

@Component({
  selector: 'app-search-todo-sheet',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatListModule,
    MatIconModule,
  ],
  template: `
    <div class="search-sheet-container">
      <h4>Filter Todos</h4>
      <form [formGroup]="searchForm" (ngSubmit)="applySearch()">
        <mat-form-field appearance="outline">
          <mat-label>Status</mat-label>
          <mat-select formControlName="status">
            <mat-option value="">All</mat-option>
            <mat-option value="PENDING">Pending</mat-option>
            <mat-option value="IN_PROGRESS">In Progress</mat-option>
            <mat-option value="COMPLETED">Completed</mat-option>
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Min Time (minutes)</mat-label>
          <input matInput type="number" formControlName="minTime" />
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Max Time (minutes)</mat-label>
          <input matInput type="number" formControlName="maxTime" />
        </mat-form-field>

        <div class="sheet-actions">
          <button mat-stroked-button type="button" (click)="resetAndClose()">
            <mat-icon>clear_all</mat-icon> Reset Filters
          </button>
          <button mat-flat-button color="primary" type="submit">
            <mat-icon>search</mat-icon> Search
          </button>
        </div>
      </form>
    </div>
  `,
  styles: [
    `
      .search-sheet-container {
        padding: 16px;
        display: flex;
        flex-direction: column;
        gap: 10px;
      }
      h4 {
        margin-top: 0;
        margin-bottom: 15px;
        text-align: center;
      }
      mat-form-field {
        width: 100%;
      }
      .sheet-actions {
        display: flex;
        justify-content: space-between;
        gap: 10px;
        margin-top: 15px;
      }
    `,
  ],
})
export class SearchTodoSheetComponent {
  searchForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private bottomSheetRef: MatBottomSheetRef<SearchTodoSheetComponent>
  ) {
    this.searchForm = this.fb.group({
      status: [''],
      minTime: [null],
      maxTime: [null],
    });
  }

  applySearch(): void {
    const formValues = this.searchForm.value;
    const criteria: SearchCriteria = {};

    if (formValues.status) {
      criteria.status = formValues.status;
    }
    // Ensure numbers are sent, or null if empty/invalid
    const minTime = parseInt(formValues.minTime, 10);
    if (!isNaN(minTime)) {
      criteria.minTime = minTime;
    }
    const maxTime = parseInt(formValues.maxTime, 10);
    if (!isNaN(maxTime)) {
      criteria.maxTime = maxTime;
    }

    // Only dismiss if there are actual criteria
    if (Object.keys(criteria).length > 0) {
      this.bottomSheetRef.dismiss(criteria);
    } else {
      // Optionally show a message or just close without action
      this.bottomSheetRef.dismiss(null); // Indicate no search needed
    }
  }

  resetAndClose(): void {
    this.bottomSheetRef.dismiss('reset'); // Send a specific signal for reset
  }
}
