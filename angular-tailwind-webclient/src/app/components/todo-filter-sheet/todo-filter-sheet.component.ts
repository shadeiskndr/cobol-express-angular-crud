import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatBottomSheetRef } from '@angular/material/bottom-sheet';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatListModule } from '@angular/material/list';

export interface TodoFilterOptions {
  statuses: string[];
  hasDueDate?: boolean;
}

interface StatusOption {
  label: string;
  value: string;
  checked: boolean;
}

@Component({
  selector: 'app-todo-filter-sheet',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatCheckboxModule,
    MatButtonModule,
    MatIconModule,
    MatListModule,
  ],
  template: `
    <div class="w-full max-w-2xl p-6">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
          Filter Todos
        </h2>
        <button
          mat-icon-button
          (click)="onClose()"
          class="text-gray-500 hover:text-gray-700"
        >
          <mat-icon>close</mat-icon>
        </button>
      </div>

      <div class="space-y-6">
        <!-- Status Filter -->
        <div>
          <h3 class="text-lg font-medium text-gray-900 dark:text-gray-200 mb-3">
            Status
          </h3>
          <div class="space-y-2">
            <label
              *ngFor="let option of statusOptions"
              class="flex items-center gap-3 cursor-pointer"
            >
              <input
                type="checkbox"
                [checked]="option.checked"
                (change)="toggleStatus(option.value)"
                class="w-4 h-4 rounded border-gray-300"
              />
              <span class="text-gray-700 dark:text-gray-300">
                {{ option.label }}
              </span>
              <span
                [ngClass]="getStatusBadgeClass(option.value)"
                class="px-2 py-1 text-xs font-semibold rounded-full"
              >
                {{ option.value }}
              </span>
            </label>
          </div>
        </div>

        <!-- Due Date Filter -->
        <div>
          <h3 class="text-lg font-medium text-gray-900 dark:text-gray-200 mb-3">
            Due Date
          </h3>
          <label class="flex items-center gap-3 cursor-pointer">
            <input
              type="checkbox"
              [checked]="hasDueDate"
              (change)="toggleHasDueDate()"
              class="w-4 h-4 rounded border-gray-300"
            />
            <span class="text-gray-700 dark:text-gray-300">
              Only show todos with due dates
            </span>
          </label>
        </div>

        <!-- Action Buttons -->
        <div class="flex gap-3 mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
          <button
            type="button"
            mat-stroked-button
            (click)="onReset()"
            class="flex-1"
          >
            Reset
          </button>
          <button
            type="button"
            mat-raised-button
            color="primary"
            (click)="onApply()"
            class="flex-1"
          >
            Apply
          </button>
        </div>
      </div>
    </div>
  `,
})
export class TodoFilterSheetComponent implements OnInit {
  private bottomSheetRef = inject(MatBottomSheetRef<TodoFilterOptions>);

  statusOptions: StatusOption[] = [
    { label: 'Pending', value: 'PENDING', checked: false },
    { label: 'In Progress', value: 'IN_PROGRESS', checked: false },
    { label: 'Completed', value: 'COMPLETED', checked: false },
  ];

  hasDueDate = false;

  ngOnInit() {
    // Initialize with default state if needed
  }

  toggleStatus(value: string) {
    const option = this.statusOptions.find((opt) => opt.value === value);
    if (option) {
      option.checked = !option.checked;
    }
  }

  toggleHasDueDate() {
    this.hasDueDate = !this.hasDueDate;
  }

  onApply() {
    const selectedStatuses = this.statusOptions
      .filter((opt) => opt.checked)
      .map((opt) => opt.value);

    const filterOptions: TodoFilterOptions = {
      statuses: selectedStatuses,
      hasDueDate: this.hasDueDate || undefined,
    };

    this.bottomSheetRef.dismiss(filterOptions);
  }

  onReset() {
    this.statusOptions.forEach((opt) => (opt.checked = false));
    this.hasDueDate = false;

    // Apply empty filters to reset view
    const filterOptions: TodoFilterOptions = {
      statuses: [],
      hasDueDate: undefined,
    };

    this.bottomSheetRef.dismiss(filterOptions);
  }

  getStatusBadgeClass(status: string): string {
    switch (status) {
      case 'PENDING':
        return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200';
      case 'IN_PROGRESS':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200';
      case 'COMPLETED':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200';
    }
  }

  onClose() {
    this.bottomSheetRef.dismiss();
  }
}
