import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { AsyncPipe, TitleCasePipe } from '@angular/common';
import { Router } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatListModule } from '@angular/material/list';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
import { MatMenuModule } from '@angular/material/menu';
import { MatBadgeModule } from '@angular/material/badge';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatBottomSheet } from '@angular/material/bottom-sheet';
import { Observable } from 'rxjs';

import { DeviceService } from '../../ngm-dev-blocks/utils/services/device.service';
import { classNames } from '../../ngm-dev-blocks/utils/functions';
import { TodoService } from '../../services/todo.service';
import { AuthService } from '../../services/auth.service';
import { ThemeService } from '../../services/theme.service';
import { Todo } from '../../models/todo';
import { User } from '../../models/user';
import {
  TodoFormDialogComponent,
  TodoFormDialogData,
  TodoFormDialogResult,
} from '../../components/todo-form-dialog/todo-form-dialog.component';
import {
  TodoDeleteDialogComponent,
  TodoDeleteDialogData,
  TodoDeleteDialogResult,
} from '../../components/todo-delete-dialog/todo-delete-dialog.component';
import {
  TodoSearchSheetComponent,
  TodoSearchCriteria,
} from '../../components/todo-search-sheet/todo-search-sheet.component';
import {
  TodoFilterSheetComponent,
  TodoFilterOptions,
} from '../../components/todo-filter-sheet/todo-filter-sheet.component';

@Component({
  selector: 'app-todos',
  templateUrl: './todos.component.html',
  imports: [
    MatToolbarModule,
    MatButtonModule,
    MatSidenavModule,
    MatListModule,
    MatIconModule,
    MatCardModule,
    MatChipsModule,
    MatMenuModule,
    MatBadgeModule,
    MatSlideToggleModule,
    AsyncPipe,
    TitleCasePipe,
  ],
})
export class TodosComponent implements OnInit {
  readonly classNames = classNames;

  private todoService = inject(TodoService);
  private authService = inject(AuthService);
  private themeService = inject(ThemeService);
  private router = inject(Router);
  private dialog = inject(MatDialog);
  private snackBar = inject(MatSnackBar);
  private bottomSheet = inject(MatBottomSheet);

  readonly isLessThanMD$ = inject(DeviceService).isLessThanMD$;
  readonly isDarkMode = () => this.themeService.darkMode();
  readonly colorTheme = () => this.themeService.colorTheme();

  todos$ = signal<Todo[]>([]);
  currentUser$!: Observable<User | null>;

  // Filter states
  selectedFilter = signal('all');
  filteredTodos = computed(() => {
    return this.filterTodos(this.todos$(), this.selectedFilter());
  });

  // Todo counts using computed signals
  pendingCount = computed(() => {
    return this.todos$().filter((todo) => todo.status === 'PENDING').length;
  });

  inProgressCount = computed(() => {
    return this.todos$().filter((todo) => todo.status === 'IN_PROGRESS').length;
  });

  completedCount = computed(() => {
    return this.todos$().filter((todo) => todo.status === 'COMPLETED').length;
  });

  readonly mainMenu: {
    label: string;
    id: string;
    icon: string;
    isActive?: boolean;
    getCount?: () => number;
  }[] = [
    {
      label: 'All Todos',
      id: 'all',
      icon: 'list',
      isActive: true,
    },
    {
      label: 'Pending',
      id: 'pending',
      icon: 'schedule',
      getCount: () => this.pendingCount(),
    },
    {
      label: 'In Progress',
      id: 'in_progress',
      icon: 'play_circle',
      getCount: () => this.inProgressCount(),
    },
    {
      label: 'Completed',
      id: 'completed',
      icon: 'check_circle',
      getCount: () => this.completedCount(),
    },
  ];

  readonly quickActions = [
    {
      label: 'Add Todo',
      id: 'add',
      icon: 'add',
    },
    {
      label: 'Search',
      id: 'search',
      icon: 'search',
    },
    // {
    //   label: 'Filter',
    //   id: 'filter',
    //   icon: 'filter_list',
    // },
  ];

  readonly settingsMenu = [
    {
      label: 'Preferences',
      id: 'preferences',
      icon: 'tune',
    },
    {
      label: 'Help & Support',
      id: 'help',
      icon: 'help_outline',
    },
    {
      label: 'About',
      id: 'about',
      icon: 'info_outline',
    },
  ];

  ngOnInit() {
    this.loadTodos();
    this.currentUser$ = this.authService.currentUser$;
  }

  loadTodos() {
    this.todoService.getTodos().subscribe((todos) => {
      this.todos$.set(todos);
    });
  }

  filterTodos(todos: Todo[], filter: string): Todo[] {
    switch (filter) {
      case 'pending':
        return todos.filter((todo) => todo.status === 'PENDING');
      case 'in_progress':
        return todos.filter((todo) => todo.status === 'IN_PROGRESS');
      case 'completed':
        return todos.filter((todo) => todo.status === 'COMPLETED');
      default:
        return todos;
    }
  }

  onFilterChange(filterId: string) {
    this.selectedFilter.set(filterId);
    this.mainMenu.forEach((item) => (item.isActive = item.id === filterId));
  }

  onQuickAction(actionId: string) {
    switch (actionId) {
      case 'add':
        this.openCreateTodoDialog();
        break;
      case 'search':
        this.openSearchSheet();
        break;
      case 'filter':
        this.openFilterSheet();
        break;
    }
  }

  onSettingsAction(actionId: string) {
    switch (actionId) {
      case 'preferences':
        console.log('Open preferences');
        break;
      case 'help':
        console.log('Open help');
        break;
      case 'about':
        console.log('Show about');
        break;
    }
  }

  onThemeToggle() {
    this.themeService.toggleTheme();
  }

  cycleColorTheme() {
    const currentTheme = this.themeService.colorTheme();
    const nextTheme = currentTheme === 'purple' ? 'ocean' : 'purple';
    this.themeService.setColorTheme(nextTheme);
  }

  openCreateTodoDialog() {
    const dialogData: TodoFormDialogData = {
      mode: 'create',
    };

    const dialogRef = this.dialog.open(TodoFormDialogComponent, {
      width: '600px',
      maxWidth: '90vw',
      data: dialogData,
      disableClose: true,
    });

    dialogRef
      .afterClosed()
      .subscribe((result: TodoFormDialogResult | undefined) => {
        if (result?.action === 'save' && result.todo) {
          this.createTodo(result.todo);
        }
      });
  }

  openEditTodoDialog(todo: Todo) {
    const dialogData: TodoFormDialogData = {
      mode: 'edit',
      todo: todo,
    };

    const dialogRef = this.dialog.open(TodoFormDialogComponent, {
      width: '600px',
      maxWidth: '90vw',
      data: dialogData,
      disableClose: true,
    });

    dialogRef
      .afterClosed()
      .subscribe((result: TodoFormDialogResult | undefined) => {
        if (result?.action === 'save' && result.todo) {
          this.updateTodo(todo.id, result.todo);
        }
      });
  }

  createTodo(todoData: Partial<Todo>) {
    this.todoService.createTodo(todoData).subscribe({
      next: (newTodo) => {
        this.snackBar.open('Todo created successfully!', 'Close', {
          duration: 3000,
          panelClass: ['success-snackbar'],
        });
        this.loadTodos(); // Refresh the list
      },
      error: (error) => {
        this.snackBar.open(
          'Failed to create todo. Please try again.',
          'Close',
          {
            duration: 5000,
            panelClass: ['error-snackbar'],
          }
        );
        console.error('Error creating todo:', error);
      },
    });
  }

  updateTodo(todoId: number, todoData: Partial<Todo>) {
    this.todoService.updateTodo(todoId, todoData).subscribe({
      next: (updatedTodo) => {
        this.snackBar.open('Todo updated successfully!', 'Close', {
          duration: 3000,
          panelClass: ['success-snackbar'],
        });
        this.loadTodos(); // Refresh the list
      },
      error: (error) => {
        this.snackBar.open(
          'Failed to update todo. Please try again.',
          'Close',
          {
            duration: 5000,
            panelClass: ['error-snackbar'],
          }
        );
        console.error('Error updating todo:', error);
      },
    });
  }

  updateTodoStatus(
    todo: Todo,
    newStatus: 'PENDING' | 'IN_PROGRESS' | 'COMPLETED'
  ) {
    const updatedTodo = { ...todo, status: newStatus };
    this.updateTodo(todo.id, updatedTodo);
  }

  deleteTodo(todo: Todo) {
    const dialogData: TodoDeleteDialogData = {
      todo: todo,
    };

    const dialogRef = this.dialog.open(TodoDeleteDialogComponent, {
      width: '500px',
      maxWidth: '90vw',
      data: dialogData,
      disableClose: true,
    });

    dialogRef
      .afterClosed()
      .subscribe((result: TodoDeleteDialogResult | undefined) => {
        if (result?.action === 'delete') {
          this.todoService.deleteTodo(todo.id).subscribe({
            next: () => {
              this.snackBar.open('Todo deleted successfully!', 'Close', {
                duration: 3000,
                panelClass: ['success-snackbar'],
              });
              this.loadTodos(); // Refresh the list
            },
            error: (error) => {
              this.snackBar.open(
                'Failed to delete todo. Please try again.',
                'Close',
                {
                  duration: 5000,
                  panelClass: ['error-snackbar'],
                }
              );
              console.error('Error deleting todo:', error);
            },
          });
        }
      });
  }

  // Action handlers for todo menu
  onEditTodo(todo: Todo) {
    this.openEditTodoDialog(todo);
  }

  onMarkAsComplete(todo: Todo) {
    this.updateTodoStatus(todo, 'COMPLETED');
  }

  onStartWorking(todo: Todo) {
    this.updateTodoStatus(todo, 'IN_PROGRESS');
  }

  onMarkAsPending(todo: Todo) {
    this.updateTodoStatus(todo, 'PENDING');
  }

  onDeleteTodo(todo: Todo) {
    this.deleteTodo(todo);
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'PENDING':
        return 'schedule';
      case 'IN_PROGRESS':
        return 'play_circle';
      case 'COMPLETED':
        return 'check_circle';
      default:
        return 'help';
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'PENDING':
        return 'text-orange-500';
      case 'IN_PROGRESS':
        return 'text-blue-500';
      case 'COMPLETED':
        return 'text-green-500';
      default:
        return 'text-gray-500';
    }
  }

  getStatusChipColor(status: string): string {
    switch (status) {
      case 'PENDING':
        return 'bg-orange-100 text-orange-800';
      case 'IN_PROGRESS':
        return 'bg-blue-100 text-blue-800';
      case 'COMPLETED':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }

  formatDueDate(dueDate: string | undefined): string {
    if (!dueDate) return '';
    const date = new Date(dueDate);
    const now = new Date();
    const diffTime = date.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays < 0) return 'Overdue';
    if (diffDays === 0) return 'Due today';
    if (diffDays === 1) return 'Due tomorrow';
    return `Due in ${diffDays} days`;
  }

  getDueDateColor(dueDate: string | undefined): string {
    if (!dueDate) return 'text-gray-500';
    const date = new Date(dueDate);
    const now = new Date();
    const diffTime = date.getTime() - now.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays < 0) return 'text-red-500';
    if (diffDays <= 1) return 'text-orange-500';
    return 'text-gray-500';
  }

  openSearchSheet() {
    const sheetRef = this.bottomSheet.open(TodoSearchSheetComponent, {
      disableClose: false,
    });

    sheetRef.afterDismissed().subscribe((result) => {
      if (result && Object.keys(result).length > 0) {
        this.performSearch(result);
      } else if (result && Object.keys(result).length === 0) {
        // Clear was clicked, reload all todos
        this.loadTodos();
        this.selectedFilter.set('all');
        this.snackBar.open('Search cleared - showing all todos', 'Close', {
          duration: 3000,
        });
      }
    });
  }

  performSearch(criteria: TodoSearchCriteria) {
    this.todoService.searchTodos(criteria).subscribe({
      next: (result: any) => {
        const todos = result.todos || result;
        this.todos$.set(Array.isArray(todos) ? todos : []);
        this.snackBar.open(`Found ${this.todos$().length} todo(s)`, 'Close', {
          duration: 3000,
        });
      },
      error: (error) => {
        this.snackBar.open('Search failed. Please try again.', 'Close', {
          duration: 5000,
          panelClass: ['error-snackbar'],
        });
        console.error('Error searching todos:', error);
      },
    });
  }

  openFilterSheet() {
    const sheetRef = this.bottomSheet.open(TodoFilterSheetComponent, {
      disableClose: false,
    });

    sheetRef.afterDismissed().subscribe((result) => {
      if (result) {
        this.applyFilters(result);
      }
    });
  }

  applyFilters(filters: TodoFilterOptions) {
    // If no filters are applied (reset), reload all todos
    if (
      (!filters.statuses || filters.statuses.length === 0) &&
      !filters.hasDueDate
    ) {
      this.loadTodos();
      this.selectedFilter.set('all');
      this.snackBar.open('Filters cleared - showing all todos', 'Close', {
        duration: 3000,
      });
      return;
    }

    let filtered = this.todos$();

    // Filter by status
    if (filters.statuses && filters.statuses.length > 0) {
      filtered = filtered.filter((todo) =>
        filters.statuses!.includes(todo.status)
      );
    }

    // Filter by due date existence
    if (filters.hasDueDate) {
      filtered = filtered.filter((todo) => todo.dueDate);
    }

    // Update the filtered todos by temporarily changing filter
    this.selectedFilter.set('filtered');
    this.todos$.set(filtered);

    this.snackBar.open(
      `Applied filters - ${filtered.length} todo(s)`,
      'Close',
      {
        duration: 3000,
      }
    );
  }

  onLogout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  onProfile() {
    this.router.navigate(['/profile']);
  }
}
