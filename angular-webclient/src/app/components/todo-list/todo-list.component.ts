import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatDialog } from '@angular/material/dialog';
import { TodoService } from '../../services/todo.service';
import { Todo } from '../../models/todo';
import { LoadingSpinnerComponent } from '../loading-spinner/loading-spinner.component';
import { DatePipe, NgClass } from '@angular/common';

@Component({
  selector: 'app-todo-list',
  standalone: true,
  imports: [
    NgClass,
    DatePipe,
    MatTableModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatChipsModule,
    LoadingSpinnerComponent,
  ],
  templateUrl: './todo-list.component.html',
  styleUrl: './todo-list.component.scss',
})
export class TodoListComponent implements OnInit {
  todos: Todo[] = [];
  displayedColumns: string[] = [
    'id',
    'description',
    'status',
    'dueDate',
    'estimatedTime',
    'actions',
  ];
  isLoading = false;

  constructor(
    private todoService: TodoService,
    private router: Router,
    private snackBar: MatSnackBar,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.loadTodos();
  }

  loadTodos(): void {
    this.isLoading = true;
    this.todoService.getTodos().subscribe({
      next: (data) => {
        this.todos = data;
        this.isLoading = false;
      },
      error: (error) => {
        this.snackBar.open(
          'Error loading todos: ' + (error.error?.error || 'Unknown error'),
          'Close',
          { duration: 3000 }
        );
        this.isLoading = false;
      },
    });
  }

  editTodo(id: number): void {
    this.router.navigate(['/todos/edit', id]);
  }

  deleteTodo(id: number): void {
    if (confirm('Are you sure you want to delete this todo?')) {
      this.todoService.deleteTodo(id).subscribe({
        next: () => {
          this.snackBar.open('Todo deleted successfully', 'Close', {
            duration: 3000,
          });
          this.loadTodos();
        },
        error: (error) => {
          this.snackBar.open(
            'Error deleting todo: ' + (error.error?.error || 'Unknown error'),
            'Close',
            { duration: 3000 }
          );
        },
      });
    }
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'COMPLETED':
        return 'status-completed';
      case 'IN_PROGRESS':
        return 'status-in-progress';
      case 'PENDING':
        return 'status-pending';
      default:
        return '';
    }
  }

  addNewTodo(): void {
    this.router.navigate(['/todos/new']);
  }
}
