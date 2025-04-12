import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { TodoService } from '../../services/todo.service';
import { AuthService } from '../../services/auth.service';
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
    MatSnackBarModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    ReactiveFormsModule,
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
  searchForm: FormGroup;
  currentUserId: number | null = null;

  constructor(
    private todoService: TodoService,
    private authService: AuthService,
    private router: Router,
    private snackBar: MatSnackBar,
    private dialog: MatDialog,
    private fb: FormBuilder
  ) {
    this.searchForm = this.fb.group({
      status: [''],
      minTime: [null],
      maxTime: [null],
    });

    // Get current user from AuthService
    this.authService.currentUser$.subscribe((user) => {
      if (user) {
        this.currentUserId = user.id;
      }
    });
  }

  ngOnInit(): void {
    this.loadTodos();
  }

  loadTodos(): void {
    this.isLoading = true;
    this.todoService.getTodos().subscribe({
      next: (data) => {
        // Filter todos by current user ID if needed
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

  searchTodos(): void {
    const criteria = this.getSearchCriteria();
    if (!this.hasValidSearchCriteria(criteria)) {
      this.snackBar.open(
        'Please provide at least one search criteria',
        'Close',
        {
          duration: 3000,
        }
      );
      return;
    }

    this.isLoading = true;
    this.todoService.searchTodos(criteria).subscribe({
      next: (data) => {
        this.todos = data;
        this.isLoading = false;
        this.snackBar.open(
          `Found ${data.length} todos matching your criteria`,
          'Close',
          {
            duration: 3000,
          }
        );
      },
      error: (error) => {
        this.snackBar.open(
          'Error searching todos: ' + (error.error?.error || 'Unknown error'),
          'Close',
          { duration: 3000 }
        );
        this.isLoading = false;
      },
    });
  }

  resetSearch(): void {
    this.searchForm.reset({
      status: '',
      minTime: null,
      maxTime: null,
    });
    this.loadTodos();
  }

  private getSearchCriteria(): any {
    const formValues = this.searchForm.value;
    const criteria: any = {};

    if (formValues.status) {
      criteria.status = formValues.status;
    }

    if (formValues.minTime !== null && formValues.minTime !== '') {
      criteria.minTime = formValues.minTime;
    }

    if (formValues.maxTime !== null && formValues.maxTime !== '') {
      criteria.maxTime = formValues.maxTime;
    }

    return criteria;
  }

  private hasValidSearchCriteria(criteria: any): boolean {
    // Simply check if there's at least one criterion
    return Object.keys(criteria).length > 0;
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
