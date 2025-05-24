import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup } from '@angular/forms';
import { MatBottomSheetRef } from '@angular/material/bottom-sheet';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSelectModule } from '@angular/material/select';

export interface TodoSearchCriteria {
  status?: string;
  minTime?: number | null;
  maxTime?: number | null;
}

@Component({
  selector: 'app-todo-search-sheet',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatSelectModule,
  ],
  template: `
    <div class="w-full max-w-2xl p-6">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-xl">
          Search Todos
        </h2>
        <button
          mat-icon-button
          (click)="onClose()"
        >
          <mat-icon>close</mat-icon>
        </button>
      </div>

      <form [formGroup]="searchForm" class="space-y-4">
         <mat-form-field class="w-full" appearance="outline" >
           <mat-label>Status</mat-label>
           <mat-select formControlName="status">
             <mat-option value="">All</mat-option>
             <mat-option value="PENDING">Pending</mat-option>
             <mat-option value="IN_PROGRESS">In Progress</mat-option>
             <mat-option value="COMPLETED">Completed</mat-option>
           </mat-select>
         </mat-form-field>

         <mat-form-field class="w-full"  appearance="outline" >
           <mat-label>Min Time (hours)</mat-label>
           <input matInput type="number" formControlName="minTime" />
         </mat-form-field>

         <mat-form-field class="w-full"  appearance="outline" >
           <mat-label>Max Time (hours)</mat-label>
           <input matInput type="number" formControlName="maxTime" />
         </mat-form-field>

        <div class="flex gap-3 mt-6">
          <button
            type="button"
            mat-stroked-button
            (click)="onClear()"
            class="flex-1"
          >
            Clear
          </button>
          <button
            type="button"
            mat-raised-button
            color="primary"
            (click)="onSearch()"
            class="flex-1"
          >
            Search
          </button>
        </div>
      </form>
    </div>
  `,
})
export class TodoSearchSheetComponent implements OnInit {
  private bottomSheetRef = inject(MatBottomSheetRef<TodoSearchCriteria>);
  private fb = inject(FormBuilder);

  searchForm!: FormGroup;

  ngOnInit() {
    this.searchForm = this.fb.group({
      status: [''],
      minTime: [null],
      maxTime: [null],
    });
  }

  onSearch() {
    const criteria = this.searchForm.value;
    // Filter out empty values
    const filteredCriteria = Object.fromEntries(
      Object.entries(criteria).filter(([_, value]) => value !== '' && value !== null)
    );
    this.bottomSheetRef.dismiss(filteredCriteria);
  }

  onClear() {
    this.searchForm.reset();
    // Dismiss with empty criteria to clear search
    this.bottomSheetRef.dismiss({});
  }

  onClose() {
    this.bottomSheetRef.dismiss();
  }
}
