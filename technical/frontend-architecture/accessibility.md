# Acessibilidade (A11y)

## Compromisso com Acessibilidade

O OrçaSonhos segue as diretrizes **WCAG 2.1 AA** para garantir que todos os usuários possam acessar e usar a aplicação, independentemente de suas habilidades ou tecnologias assistivas.

## Padrões de Design System

### Cores e Contraste

```scss
// shared/theme/_accessibility.scss
:root {
  /* Ratios de contraste WCAG AA (4.5:1 mínimo) */
  --os-text-on-light: #212121;      /* 16:1 contrast ratio */
  --os-text-on-dark: #FFFFFF;       /* 21:1 contrast ratio */  
  --os-text-secondary: #616161;     /* 7.4:1 contrast ratio */
  --os-link-color: #1565C0;         /* 5.7:1 contrast ratio */
  
  /* Estados de foco - contraste mínimo 3:1 */
  --os-focus-ring: 2px solid #2196F3;
  --os-focus-ring-offset: 2px;
  
  /* Estados de erro - contraste adequado */
  --os-error-text: #C62828;         /* 5.1:1 contrast ratio */
  --os-error-background: #FFEBEE;   /* Background para contexto */
}

/* Verificação automática de contraste */
.os-text {
  color: var(--os-text-on-light);
  
  /* Garantir contraste em backgrounds dinâmicos */
  &[data-bg="dark"] {
    color: var(--os-text-on-dark);
  }
}

/* Focus ring consistente */
.os-focusable {
  &:focus {
    outline: var(--os-focus-ring);
    outline-offset: var(--os-focus-ring-offset);
  }
  
  &:focus:not(:focus-visible) {
    outline: none; /* Remove outline para mouse users */
  }
}
```

### Componentes Acessíveis

```typescript
// shared/ui-components/atoms/os-button/os-button.component.ts
@Component({
  selector: 'os-button',
  template: `
    <button 
      [type]="type()"
      [disabled]="disabled() || loading()"
      [attr.aria-label]="ariaLabel()"
      [attr.aria-describedby]="ariaDescribedBy()"
      [attr.aria-pressed]="pressed()"
      class="os-button os-focusable"
      [class]="buttonClass()"
      (click)="handleClick($event)">
      
      @if (loading()) {
        <span 
          class="os-button__spinner"
          role="status" 
          aria-label="Carregando">
          <os-spinner size="small" />
        </span>
      }
      
      @if (icon() && !loading()) {
        <os-icon 
          [name]="icon()" 
          [attr.aria-hidden]="true" 
          class="os-button__icon" />
      }
      
      <span class="os-button__text">
        <ng-content />
      </span>
    </button>
  `,
  styleUrls: ['./os-button.component.scss']
})
export class OsButtonComponent {
  // Accessibility inputs
  ariaLabel = input<string>();
  ariaDescribedBy = input<string>(); 
  pressed = input<boolean>();
  type = input<'button' | 'submit' | 'reset'>('button');
  
  // Standard inputs
  variant = input<ButtonVariant>('primary');
  disabled = input(false);
  loading = input(false);
  icon = input<string>();
  
  onClick = output<MouseEvent>();
  
  protected handleClick(event: MouseEvent): void {
    if (!this.disabled() && !this.loading()) {
      this.onClick.emit(event);
    }
  }
  
  protected buttonClass = computed(() => [
    'os-button',
    `os-button--${this.variant()}`,
    this.loading() ? 'os-button--loading' : '',
    this.disabled() ? 'os-button--disabled' : ''
  ].filter(Boolean).join(' '));
}
```

### Form Accessibility

```typescript
// shared/ui-components/molecules/os-form-field/os-form-field.component.ts
@Component({
  selector: 'os-form-field',
  template: `
    <div class="os-form-field" [class.os-form-field--error]="hasError()">
      <label 
        [for]="fieldId()"
        [id]="labelId()"
        class="os-form-field__label"
        [class.os-form-field__label--required]="required()">
        {{ label() }}
        @if (required()) {
          <span class="os-form-field__required" aria-label="obrigatório">*</span>
        }
      </label>
      
      <div class="os-form-field__input-container">
        <div 
          class="os-form-field__input"
          [attr.aria-labelledby]="labelId()"
          [attr.aria-describedby]="getDescribedByIds()"
          [attr.aria-invalid]="hasError()">
          <ng-content select="[slot=input]" />
        </div>
        
        @if (suffix()) {
          <div class="os-form-field__suffix" [attr.aria-hidden]="true">
            <ng-content select="[slot=suffix]" />
          </div>
        }
      </div>
      
      @if (hint() && !hasError()) {
        <div 
          [id]="hintId()"
          class="os-form-field__hint"
          role="note">
          {{ hint() }}
        </div>
      }
      
      @if (error()) {
        <div 
          [id]="errorId()"
          class="os-form-field__error"
          role="alert"
          aria-live="polite">
          <os-icon name="error" aria-hidden="true" />
          {{ error() }}
        </div>
      }
    </div>
  `,
  styleUrls: ['./os-form-field.component.scss']
})
export class OsFormFieldComponent {
  private uniqueId = Math.random().toString(36).substr(2, 9);
  
  label = input.required<string>();
  hint = input<string>();
  error = input<string>();
  required = input(false);
  suffix = input(false);
  
  protected fieldId = computed(() => `os-field-${this.uniqueId}`);
  protected labelId = computed(() => `os-label-${this.uniqueId}`);
  protected hintId = computed(() => `os-hint-${this.uniqueId}`);
  protected errorId = computed(() => `os-error-${this.uniqueId}`);
  
  protected hasError = computed(() => !!this.error());
  
  protected getDescribedByIds = computed(() => {
    const ids = [];
    
    if (this.hint() && !this.hasError()) {
      ids.push(this.hintId());
    }
    
    if (this.hasError()) {
      ids.push(this.errorId());
    }
    
    return ids.join(' ') || undefined;
  });
}
```

## Navegação por Teclado

### Focus Management

```typescript
// shared/services/focus-trap.service.ts
@Injectable({ providedIn: 'root' })
export class FocusTrapService {
  createFocusTrap(element: HTMLElement): FocusTrap {
    const focusableElements = this.getFocusableElements(element);
    const firstFocusable = focusableElements[0];
    const lastFocusable = focusableElements[focusableElements.length - 1];
    
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Tab') return;
      
      if (event.shiftKey) {
        // Shift + Tab
        if (document.activeElement === firstFocusable) {
          lastFocusable.focus();
          event.preventDefault();
        }
      } else {
        // Tab  
        if (document.activeElement === lastFocusable) {
          firstFocusable.focus();
          event.preventDefault();
        }
      }
    };
    
    element.addEventListener('keydown', handleKeyDown);
    
    // Focus first element
    firstFocusable?.focus();
    
    return {
      destroy: () => {
        element.removeEventListener('keydown', handleKeyDown);
      }
    };
  }
  
  private getFocusableElements(container: HTMLElement): HTMLElement[] {
    const selector = [
      'button:not([disabled])',
      '[href]',
      'input:not([disabled])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      '[tabindex]:not([tabindex="-1"]):not([disabled])',
      '[contenteditable]:not([contenteditable="false"])'
    ].join(',');
    
    return Array.from(container.querySelectorAll(selector))
      .filter(el => this.isVisible(el)) as HTMLElement[];
  }
  
  private isVisible(element: Element): boolean {
    const style = window.getComputedStyle(element);
    return style.display !== 'none' && 
           style.visibility !== 'hidden' && 
           style.opacity !== '0';
  }
}

interface FocusTrap {
  destroy(): void;
}
```

### Skip Links

```typescript
// shared/ui-components/atoms/os-skip-link/os-skip-link.component.ts
@Component({
  selector: 'os-skip-link',
  template: `
    <a 
      [href]="href()"
      class="os-skip-link"
      (click)="handleClick($event)">
      {{ text() }}
    </a>
  `,
  styles: [`
    .os-skip-link {
      position: absolute;
      top: -40px;
      left: 6px;
      z-index: 1000;
      padding: 8px;
      background: var(--os-color-primary-500);
      color: white;
      text-decoration: none;
      border-radius: 4px;
      transition: top 0.2s ease;
      
      &:focus {
        top: 6px;
      }
    }
  `]
})
export class OsSkipLinkComponent {
  href = input.required<string>();
  text = input<string>('Pular para conteúdo principal');
  
  protected handleClick(event: MouseEvent): void {
    event.preventDefault();
    
    const target = document.querySelector(this.href()) as HTMLElement;
    if (target) {
      target.focus();
      target.scrollIntoView({ behavior: 'smooth' });
    }
  }
}
```

## Modal e Dialog Accessibility

```typescript
// shared/ui-components/organisms/os-modal/os-modal.component.ts
@Component({
  selector: 'os-modal',
  template: `
    @if (isOpen()) {
      <div 
        class="os-modal-overlay"
        role="dialog"
        [attr.aria-modal]="true"
        [attr.aria-labelledby]="titleId()"
        [attr.aria-describedby]="descriptionId()"
        (click)="handleOverlayClick($event)">
        
        <div 
          class="os-modal"
          [style.max-width]="maxWidth()"
          (click)="$event.stopPropagation()"
          #modalRef>
          
          <header class="os-modal__header">
            <h2 [id]="titleId()" class="os-modal__title">
              <ng-content select="[slot=title]" />
            </h2>
            
            <os-button 
              variant="tertiary"
              icon="close"
              [ariaLabel]="'Fechar modal'"
              (osClick)="close()"
              class="os-modal__close" />
          </header>
          
          <div [id]="descriptionId()" class="os-modal__content">
            <ng-content />
          </div>
          
          @if (hasActions()) {
            <footer class="os-modal__actions">
              <ng-content select="[slot=actions]" />
            </footer>
          }
        </div>
      </div>
    }
  `,
  styleUrls: ['./os-modal.component.scss']
})
export class OsModalComponent implements OnInit, OnDestroy {
  private focusTrap = inject(FocusTrapService);
  private focusTrapInstance?: FocusTrap;
  private previouslyFocusedElement?: HTMLElement;
  
  private uniqueId = Math.random().toString(36).substr(2, 9);
  
  isOpen = input.required<boolean>();
  maxWidth = input<string>('600px');
  hasActions = input(false);
  closeOnOverlayClick = input(true);
  
  onClose = output<void>();
  
  @ViewChild('modalRef') modalRef?: ElementRef<HTMLElement>;
  
  protected titleId = computed(() => `os-modal-title-${this.uniqueId}`);
  protected descriptionId = computed(() => `os-modal-desc-${this.uniqueId}`);
  
  ngOnInit(): void {
    // Watch for open state changes
    effect(() => {
      if (this.isOpen()) {
        this.openModal();
      } else {
        this.closeModal();
      }
    });
  }
  
  ngOnDestroy(): void {
    this.closeModal();
  }
  
  private openModal(): void {
    // Store previously focused element
    this.previouslyFocusedElement = document.activeElement as HTMLElement;
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden';
    
    // Setup focus trap
    setTimeout(() => {
      if (this.modalRef) {
        this.focusTrapInstance = this.focusTrap.createFocusTrap(
          this.modalRef.nativeElement
        );
      }
    });
    
    // Listen for Escape key
    document.addEventListener('keydown', this.handleEscapeKey);
  }
  
  private closeModal(): void {
    // Restore body scroll
    document.body.style.overflow = '';
    
    // Destroy focus trap
    this.focusTrapInstance?.destroy();
    this.focusTrapInstance = undefined;
    
    // Restore focus
    this.previouslyFocusedElement?.focus();
    this.previouslyFocusedElement = undefined;
    
    // Remove event listeners
    document.removeEventListener('keydown', this.handleEscapeKey);
  }
  
  private handleEscapeKey = (event: KeyboardEvent): void => {
    if (event.key === 'Escape') {
      this.close();
    }
  };
  
  protected handleOverlayClick(event: MouseEvent): void {
    if (this.closeOnOverlayClick() && event.target === event.currentTarget) {
      this.close();
    }
  }
  
  protected close(): void {
    this.onClose.emit();
  }
}
```

## Screen Reader Support

### Announcements

```typescript
// shared/services/screen-reader.service.ts
@Injectable({ providedIn: 'root' })
export class ScreenReaderService {
  private announcementContainer?: HTMLElement;
  
  constructor() {
    this.createAnnouncementContainer();
  }
  
  // Announce messages to screen readers
  announce(message: string, priority: 'polite' | 'assertive' = 'polite'): void {
    if (!this.announcementContainer) {
      this.createAnnouncementContainer();
    }
    
    // Clear previous announcement
    this.announcementContainer!.textContent = '';
    
    // Set aria-live priority
    this.announcementContainer!.setAttribute('aria-live', priority);
    
    // Announce new message
    setTimeout(() => {
      this.announcementContainer!.textContent = message;
    }, 100);
    
    // Clear message after announcement
    setTimeout(() => {
      this.announcementContainer!.textContent = '';
    }, 3000);
  }
  
  // Announce status changes (form validation, loading states, etc.)
  announceStatus(status: string): void {
    this.announce(status, 'assertive');
  }
  
  // Announce navigation changes
  announceNavigation(location: string): void {
    this.announce(`Navegando para ${location}`, 'polite');
  }
  
  private createAnnouncementContainer(): void {
    this.announcementContainer = document.createElement('div');
    this.announcementContainer.setAttribute('aria-live', 'polite');
    this.announcementContainer.setAttribute('aria-atomic', 'true');
    this.announcementContainer.style.cssText = `
      position: absolute !important;
      left: -10000px !important;
      width: 1px !important;
      height: 1px !important;
      overflow: hidden !important;
    `;
    
    document.body.appendChild(this.announcementContainer);
  }
}
```

### Data Tables Accessibility

```typescript
// shared/ui-components/organisms/os-data-table/os-data-table.component.ts
@Component({
  selector: 'os-data-table',
  template: `
    <div class="os-data-table">
      <table 
        class="os-data-table__table"
        role="table"
        [attr.aria-label]="ariaLabel()"
        [attr.aria-describedby]="ariaDescribedBy()">
        
        <thead role="rowgroup">
          <tr role="row">
            @for (column of columns(); track column.key) {
              <th 
                role="columnheader"
                [attr.aria-sort]="getAriaSort(column)"
                [class.os-data-table__header--sortable]="column.sortable"
                (click)="column.sortable && sort(column.key)"
                (keydown)="handleHeaderKeydown($event, column)">
                
                {{ column.label }}
                
                @if (column.sortable) {
                  <span class="sr-only">
                    {{ getSortDescription(column) }}
                  </span>
                  
                  @if (sortColumn() === column.key) {
                    <os-icon 
                      [name]="sortDirection() === 'asc' ? 'arrow-up' : 'arrow-down'"
                      [attr.aria-hidden]="true"
                      class="os-data-table__sort-icon" />
                  }
                }
              </th>
            }
          </tr>
        </thead>
        
        <tbody role="rowgroup">
          @for (item of sortedData(); track trackFn($index, item); let rowIndex = $index) {
            <tr role="row" [attr.aria-rowindex]="rowIndex + 2">
              @for (column of columns(); track column.key) {
                <td 
                  role="gridcell"
                  [attr.aria-describedby]="column.describedBy">
                  <ng-container [ngTemplateOutlet]="column.template || defaultCell" 
                                [ngTemplateOutletContext]="{$implicit: item, column: column}" />
                </td>
              }
            </tr>
          }
        </tbody>
      </table>
      
      @if (data().length === 0) {
        <div class="os-data-table__empty" role="status">
          <ng-content select="[slot=empty]" />
        </div>
      }
    </div>
  `,
  styleUrls: ['./os-data-table.component.scss']
})
export class OsDataTableComponent<T> {
  private screenReader = inject(ScreenReaderService);
  
  data = input.required<T[]>();
  columns = input.required<TableColumn<T>[]>();
  trackFn = input<TrackByFunction<T>>((index, item) => item);
  ariaLabel = input<string>();
  ariaDescribedBy = input<string>();
  
  // Sorting state
  private sortColumn = signal<keyof T | null>(null);
  private sortDirection = signal<'asc' | 'desc'>('asc');
  
  protected sort(column: keyof T): void {
    if (this.sortColumn() === column) {
      // Toggle direction
      this.sortDirection.update(dir => dir === 'asc' ? 'desc' : 'asc');
    } else {
      // New column
      this.sortColumn.set(column);
      this.sortDirection.set('asc');
    }
    
    // Announce sort change
    const columnObj = this.columns().find(col => col.key === column);
    const direction = this.sortDirection() === 'asc' ? 'crescente' : 'decrescente';
    this.screenReader.announceStatus(
      `Tabela ordenada por ${columnObj?.label} em ordem ${direction}`
    );
  }
  
  protected getAriaSort(column: TableColumn<T>): string | undefined {
    if (!column.sortable) return undefined;
    
    if (this.sortColumn() === column.key) {
      return this.sortDirection() === 'asc' ? 'ascending' : 'descending';
    }
    
    return 'none';
  }
  
  protected getSortDescription(column: TableColumn<T>): string {
    if (this.sortColumn() === column.key) {
      const nextDirection = this.sortDirection() === 'asc' ? 'decrescente' : 'crescente';
      return `Ordenar por ${column.label} em ordem ${nextDirection}`;
    }
    
    return `Ordenar por ${column.label}`;
  }
  
  protected handleHeaderKeydown(event: KeyboardEvent, column: TableColumn<T>): void {
    if (column.sortable && (event.key === 'Enter' || event.key === ' ')) {
      event.preventDefault();
      this.sort(column.key);
    }
  }
}
```

## Testing Accessibility

### Automated A11y Tests

```typescript
// shared/testing/accessibility.helpers.ts
import { ComponentFixture } from '@angular/core/testing';

export async function expectA11y(fixture: ComponentFixture<any>): Promise<void> {
  const element = fixture.nativeElement;
  
  // Basic ARIA checks
  expectValidAriaAttributes(element);
  expectValidLabelAssociations(element);
  expectKeyboardAccessible(element);
  expectColorContrast(element);
}

function expectValidAriaAttributes(element: HTMLElement): void {
  const elementsWithAriaLabel = element.querySelectorAll('[aria-label]');
  elementsWithAriaLabel.forEach(el => {
    expect(el.getAttribute('aria-label')).toBeTruthy();
  });
  
  const elementsWithAriaLabelledBy = element.querySelectorAll('[aria-labelledby]');
  elementsWithAriaLabelledBy.forEach(el => {
    const labelId = el.getAttribute('aria-labelledby');
    const labelElement = element.querySelector(`#${labelId}`);
    expect(labelElement).toBeTruthy();
  });
}

function expectValidLabelAssociations(element: HTMLElement): void {
  const inputs = element.querySelectorAll('input, select, textarea');
  inputs.forEach(input => {
    const id = input.getAttribute('id');
    const ariaLabel = input.getAttribute('aria-label');
    const ariaLabelledBy = input.getAttribute('aria-labelledby');
    
    if (id) {
      const label = element.querySelector(`label[for="${id}"]`);
      expect(label || ariaLabel || ariaLabelledBy).toBeTruthy();
    } else {
      expect(ariaLabel || ariaLabelledBy).toBeTruthy();
    }
  });
}

function expectKeyboardAccessible(element: HTMLElement): void {
  const interactiveElements = element.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  
  interactiveElements.forEach(el => {
    // Should be focusable
    expect(el.getAttribute('tabindex')).not.toBe('-1');
  });
}

function expectColorContrast(element: HTMLElement): void {
  // Basic color contrast checks (simplified)
  const textElements = element.querySelectorAll('p, span, div, h1, h2, h3, h4, h5, h6');
  
  textElements.forEach(el => {
    const style = window.getComputedStyle(el);
    const color = style.color;
    const backgroundColor = style.backgroundColor;
    
    // Ensure colors are not the same (basic check)
    expect(color).not.toBe(backgroundColor);
  });
}
```

### Component A11y Tests

```typescript
// shared/ui-components/atoms/os-button/os-button.component.spec.ts
describe('OsButtonComponent Accessibility', () => {
  let component: OsButtonComponent;
  let fixture: ComponentFixture<OsButtonComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OsButtonComponent]
    }).compileComponents();

    fixture = TestBed.createComponent(OsButtonComponent);
    component = fixture.componentInstance;
  });

  it('should have proper ARIA attributes', async () => {
    fixture.componentRef.setInput('ariaLabel', 'Save document');
    fixture.detectChanges();

    const button = fixture.debugElement.query(By.css('button'));
    expect(button.nativeElement.getAttribute('aria-label')).toBe('Save document');

    await expectA11y(fixture);
  });

  it('should be keyboard accessible', () => {
    const onClickSpy = jest.fn();
    fixture.componentRef.instance.onClick.subscribe(onClickSpy);

    const button = fixture.debugElement.query(By.css('button'));
    
    // Should be focusable
    button.nativeElement.focus();
    expect(document.activeElement).toBe(button.nativeElement);

    // Should respond to Enter key
    button.triggerEventHandler('keydown', { key: 'Enter', preventDefault: jest.fn() });
    expect(onClickSpy).toHaveBeenCalled();

    // Should respond to Space key
    button.triggerEventHandler('keydown', { key: ' ', preventDefault: jest.fn() });
    expect(onClickSpy).toHaveBeenCalledTimes(2);
  });

  it('should announce loading state to screen readers', () => {
    fixture.componentRef.setInput('loading', true);
    fixture.detectChanges();

    const loadingElement = fixture.debugElement.query(By.css('[role="status"]'));
    expect(loadingElement).toBeTruthy();
    expect(loadingElement.nativeElement.getAttribute('aria-label')).toBe('Carregando');
  });
});
```

---

**Ver também:**
- [UI System](./ui-system.md) - Componentes acessíveis do Design System
- [Responsive Design](./responsive-design.md) - Acessibilidade em diferentes dispositivos
- [Testing Strategy](./testing-strategy.md) - Como testar acessibilidade