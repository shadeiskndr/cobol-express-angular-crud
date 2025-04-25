import { Component, Inject, signal } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import {
  MatDialogModule,
  MatDialogRef,
  MAT_DIALOG_DATA,
} from '@angular/material/dialog';
import { MatSelectModule } from '@angular/material/select';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatSliderModule } from '@angular/material/slider';
import {
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { Todo } from '../../models/todo';

export interface TodoFormDialogData {
  todo?: Todo;
  mode: 'create' | 'edit';
}

export interface TodoFormDialogResult {
  action: 'save' | 'cancel';
  todo?: Partial<Todo>;
}

@Component({
  selector: 'app-todo-form-dialog',
  templateUrl: './todo-form-dialog.component.html',
  imports: [
    MatIconModule,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    MatDialogModule,
    MatSelectModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatSliderModule,
    ReactiveFormsModule,
  ],
})
export class TodoFormDialogComponent {
  isLoading = signal(false);

  todoForm = new FormGroup({
    description: new FormControl('', [
      Validators.required,
      Validators.minLength(3),
      Validators.maxLength(255),
    ]),
    status: new FormControl<'PENDING' | 'IN_PROGRESS' | 'COMPLETED'>(
      'PENDING',
      [Validators.required]
    ),
    dueDate: new FormControl<Date | null>(null),
    estimatedTime: new FormControl<number | null>(null, [
      Validators.min(0.5),
      Validators.max(100),
    ]),
  });

  readonly statusOptions = [
    {
      value: 'PENDING',
      label: 'Pending',
      icon: 'schedule',
      color: 'text-orange-500',
    },
    {
      value: 'IN_PROGRESS',
      label: 'In Progress',
      icon: 'play_circle',
      color: 'text-blue-500',
    },
    {
      value: 'COMPLETED',
      label: 'Completed',
      icon: 'check_circle',
      color: 'text-green-500',
    },
  ];

  readonly estimatedTimeOptions = [
    { value: 0.5, label: '30 minutes' },
    { value: 1, label: '1 hour' },
    { value: 2, label: '2 hours' },
    { value: 4, label: '4 hours' },
    { value: 8, label: '1 day' },
    { value: 16, label: '2 days' },
    { value: 24, label: '3 days' },
    { value: 40, label: '1 week' },
  ];

  constructor(
    public dialogRef: MatDialogRef<
      TodoFormDialogComponent,
      TodoFormDialogResult
    >,
    @Inject(MAT_DIALOG_DATA) public data: TodoFormDialogData
  ) {
    // If editing, populate form with existing todo data
    if (this.data.mode === 'edit' && this.data.todo) {
      this.populateForm(this.data.todo);
    }
  }

  get isEditMode(): boolean {
    return this.data.mode === 'edit';
  }

  get dialogTitle(): string {
    return this.isEditMode ? 'Edit Todo' : 'Create New Todo';
  }

  get submitButtonText(): string {
    return this.isEditMode ? 'Update Todo' : 'Create Todo';
  }

  populateForm(todo: Todo) {
    this.todoForm.patchValue({
      description: todo.description,
      status: todo.status,
      dueDate: todo.dueDate ? new Date(todo.dueDate) : null,
      estimatedTime: todo.estimatedTime || null,
    });
  }

  onSubmit() {
    if (this.todoForm.valid && !this.isLoading()) {
      this.isLoading.set(true);

      const formValue = this.todoForm.value;
      const todoData: Partial<Todo> = {
        description: formValue.description!,
        status: formValue.status!,
        dueDate: formValue.dueDate
          ? formValue.dueDate.toISOString().split('T')[0]
          : undefined,
        estimatedTime: formValue.estimatedTime || undefined,
      };

      // If editing, include the ID
      if (this.isEditMode && this.data.todo) {
        todoData.id = this.data.todo.id;
      }

      // Simulate API call delay
      setTimeout(() => {
        this.isLoading.set(false);
        this.dialogRef.close({
          action: 'save',
          todo: todoData,
        });
      }, 500);
    }
  }

  onCancel() {
    this.dialogRef.close({
      action: 'cancel',
    });
  }

  onClearDueDate() {
    this.todoForm.patchValue({ dueDate: null });
  }

  onClearEstimatedTime() {
    this.todoForm.patchValue({ estimatedTime: null });
  }

  getEstimatedTimeLabel(value: number): string {
    const option = this.estimatedTimeOptions.find((opt) => opt.value === value);
    return option ? option.label : `${value} hours`;
  }

  formatSliderValue(value: number): string {
    if (value < 1) {
      return `${value * 60}m`;
    } else if (value < 8) {
      return `${value}h`;
    } else {
      const days = Math.round(value / 8);
      return `${days}d`;
    }
  }
}
