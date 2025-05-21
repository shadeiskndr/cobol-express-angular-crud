import { Component, Inject, signal } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import {
  MatDialogModule,
  MatDialogRef,
  MAT_DIALOG_DATA,
} from '@angular/material/dialog';
import { Todo } from '../../models/todo';

export interface TodoDeleteDialogData {
  todo: Todo;
}

export interface TodoDeleteDialogResult {
  action: 'delete' | 'cancel';
}

@Component({
  selector: 'app-todo-delete-dialog',
  templateUrl: './todo-delete-dialog.component.html',
  imports: [MatIconModule, MatButtonModule, MatDialogModule],
})
export class TodoDeleteDialogComponent {
  isLoading = signal(false);

  constructor(
    public dialogRef: MatDialogRef<
      TodoDeleteDialogComponent,
      TodoDeleteDialogResult
    >,
    @Inject(MAT_DIALOG_DATA) public data: TodoDeleteDialogData
  ) {}

  onDelete() {
    if (!this.isLoading()) {
      this.isLoading.set(true);

      // Simulate API call delay
      setTimeout(() => {
        this.isLoading.set(false);
        this.dialogRef.close({
          action: 'delete',
        });
      }, 500);
    }
  }

  onCancel() {
    this.dialogRef.close({
      action: 'cancel',
    });
  }
}
