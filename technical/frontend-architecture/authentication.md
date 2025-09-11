# Autenticação Firebase

## Decisão Arquitetural

Adotamos **Firebase Authentication** como provedor de identidade com fluxo **redirect-based** para SPAs. O backend permanece totalmente **stateless**, recebendo apenas o **Bearer ID Token** no header `Authorization`.

## Motivação

1. **Simplicidade**: Firebase Auth reduz complexidade de implementação OAuth/OIDC
2. **Integração**: SDK robusto para Angular e alinhamento com backend Node.js
3. **Múltiplos Provedores**: Suporte nativo a Google, email/senha, etc.
4. **Escalabilidade**: Infraestrutura gerenciada pelo Google
5. **Segurança**: Validação automática de tokens e rotação de chaves

## Configuração Firebase

### Environment Configuration
```typescript
// environments/environment.ts
export const environment = {
  production: false,
  firebase: {
    apiKey: 'AIzaSyC...',
    authDomain: 'orcasonhos-dev.firebaseapp.com',
    projectId: 'orcasonhos-dev',
    appId: '1:123456789:web:abc123...'
  },
  flags: {
    authDisabled: false, // Feature flag para desenvolvimento
    mswEnabled: true
  }
};
```

### Firebase Initialization
```typescript
// infra/auth/firebase-config.ts
import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { environment } from '@environments/environment';

const app = initializeApp(environment.firebase);
export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();

// Configurações do provedor Google
googleProvider.addScope('email');
googleProvider.addScope('profile');
googleProvider.setCustomParameters({
  prompt: 'select_account' // Sempre mostrar seleção de conta
});
```

## Implementation Layers

### 1. Firebase Auth Adapter (Infra)
```typescript
// infra/adapters/auth/FirebaseAuthAdapter.ts
export interface IAuthAdapter {
  signInWithGoogle(): Promise<Either<AuthError, void>>;
  signOut(): Promise<Either<AuthError, void>>;
  getCurrentUser(): Promise<Either<AuthError, User | null>>;
  getIdToken(): Promise<Either<AuthError, string | null>>;
  onAuthStateChanged(callback: (user: User | null) => void): () => void;
}

@Injectable({ providedIn: 'root' })
export class FirebaseAuthAdapter implements IAuthAdapter {
  async signInWithGoogle(): Promise<Either<AuthError, void>> {
    try {
      await signInWithRedirect(auth, googleProvider);
      return Either.success(undefined);
    } catch (error) {
      return Either.error(new AuthError('Failed to sign in with Google'));
    }
  }

  async signOut(): Promise<Either<AuthError, void>> {
    try {
      await signOut(auth);
      return Either.success(undefined);
    } catch (error) {
      return Either.error(new AuthError('Failed to sign out'));
    }
  }

  async getCurrentUser(): Promise<Either<AuthError, User | null>> {
    try {
      const user = auth.currentUser;
      return Either.success(user);
    } catch (error) {
      return Either.error(new AuthError('Failed to get current user'));
    }
  }

  async getIdToken(): Promise<Either<AuthError, string | null>> {
    try {
      const user = auth.currentUser;
      if (!user) {
        return Either.success(null);
      }
      
      const token = await user.getIdToken();
      return Either.success(token);
    } catch (error) {
      return Either.error(new AuthError('Failed to get ID token'));
    }
  }

  onAuthStateChanged(callback: (user: User | null) => void): () => void {
    return onAuthStateChanged(auth, callback);
  }
}
```

### 2. Auth Service (Application)
```typescript
// application/services/AuthService.ts
export interface AuthUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
  emailVerified: boolean;
}

export interface IAuthService {
  signInWithGoogle(): Promise<Either<AuthError, void>>;
  signOut(): Promise<Either<AuthError, void>>;
  getCurrentUser(): Promise<Either<AuthError, AuthUser | null>>;
  getAccessToken(): Promise<Either<AuthError, string | null>>;
}

@Injectable({ providedIn: 'root' })
export class AuthService implements IAuthService {
  constructor(private authAdapter: IAuthAdapter) {}

  async signInWithGoogle(): Promise<Either<AuthError, void>> {
    return this.authAdapter.signInWithGoogle();
  }

  async signOut(): Promise<Either<AuthError, void>> {
    return this.authAdapter.signOut();
  }

  async getCurrentUser(): Promise<Either<AuthError, AuthUser | null>> {
    const result = await this.authAdapter.getCurrentUser();
    
    if (result.hasError) {
      return result;
    }

    const user = result.data;
    if (!user) {
      return Either.success(null);
    }

    return Either.success({
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified
    });
  }

  async getAccessToken(): Promise<Either<AuthError, string | null>> {
    return this.authAdapter.getIdToken();
  }
}
```

### 3. Auth State Management (UI)
```typescript
// app/services/auth-state.service.ts
export type AuthState = 'authenticated' | 'unauthenticated' | 'loading' | 'redirecting';

@Injectable({ providedIn: 'root' })
export class AuthStateService {
  private authService = inject(AuthService);
  private router = inject(Router);
  
  // Estado reativo com signals
  private _user = signal<AuthUser | null>(null);
  private _state = signal<AuthState>('loading');
  private _error = signal<string | null>(null);

  // Public readonly signals
  readonly user = this._user.asReadonly();
  readonly state = this._state.asReadonly();
  readonly error = this._error.asReadonly();
  
  // Computed states
  readonly isAuthenticated = computed(() => this.state() === 'authenticated');
  readonly isLoading = computed(() => this.state() === 'loading');

  constructor() {
    this.initializeAuthState();
    this.handleRedirectResult();
  }

  private initializeAuthState() {
    // Listen to auth state changes
    this.authService.authAdapter.onAuthStateChanged(async (user) => {
      if (user) {
        const userResult = await this.authService.getCurrentUser();
        if (userResult.hasError) {
          this._error.set(userResult.error.message);
          this._state.set('unauthenticated');
        } else {
          this._user.set(userResult.data);
          this._state.set('authenticated');
          this._error.set(null);
        }
      } else {
        this._user.set(null);
        this._state.set('unauthenticated');
        this._error.set(null);
      }
    });
  }

  private async handleRedirectResult() {
    try {
      this._state.set('redirecting');
      const result = await getRedirectResult(auth);
      
      if (result) {
        // Usuário foi redirecionado após autenticação
        console.log('Authentication successful via redirect');
      }
    } catch (error) {
      console.error('Redirect result error:', error);
      this._error.set('Authentication failed');
      this._state.set('unauthenticated');
    }
  }

  async signInWithGoogle(): Promise<void> {
    this._state.set('redirecting');
    this._error.set(null);
    
    const result = await this.authService.signInWithGoogle();
    
    if (result.hasError) {
      this._error.set(result.error.message);
      this._state.set('unauthenticated');
    }
    // Estado será atualizado pelo listener onAuthStateChanged
  }

  async signOut(): Promise<void> {
    const result = await this.authService.signOut();
    
    if (result.hasError) {
      this._error.set(result.error.message);
    } else {
      this.router.navigate(['/login']);
    }
  }
}
```

## Route Guards

### Auth Guard
```typescript
// app/guards/auth.guard.ts
@Injectable({ providedIn: 'root' })
export class AuthGuard implements CanActivate {
  private authState = inject(AuthStateService);
  private router = inject(Router);

  canActivate(route: ActivatedRouteSnapshot): Observable<boolean> {
    return this.authState.state().pipe(
      map(state => {
        // Feature flag para desenvolvimento
        if (environment.flags.authDisabled) {
          return true;
        }

        switch (state) {
          case 'authenticated':
            return true;
            
          case 'unauthenticated':
            this.router.navigate(['/login']);
            return false;
            
          case 'loading':
          case 'redirecting':
            // Aguardar resolução do estado
            return false;
            
          default:
            return false;
        }
      }),
      filter(result => result !== false || this.authState.state() !== 'loading'),
      take(1)
    );
  }
}
```

### Public Guard (para rotas de login)
```typescript
// app/guards/public.guard.ts
@Injectable({ providedIn: 'root' })
export class PublicGuard implements CanActivate {
  private authState = inject(AuthStateService);
  private router = inject(Router);

  canActivate(): Observable<boolean> {
    return this.authState.isAuthenticated().pipe(
      map(isAuth => {
        if (isAuth && !environment.flags.authDisabled) {
          this.router.navigate(['/dashboard']);
          return false;
        }
        return true;
      }),
      take(1)
    );
  }
}
```

## HTTP Integration

### Auth Token Provider
```typescript
// infra/auth/auth-token.provider.ts
export interface IAuthTokenProvider {
  getToken(): Promise<string | null>;
}

@Injectable({ providedIn: 'root' })
export class FirebaseTokenProvider implements IAuthTokenProvider {
  private authService = inject(AuthService);

  async getToken(): Promise<string | null> {
    const result = await this.authService.getAccessToken();
    return result.hasError ? null : result.data;
  }
}
```

### HTTP Client Integration
```typescript
// infra/http/fetch-http-client.ts  
@Injectable({ providedIn: 'root' })
export class FetchHttpClient implements IHttpClient {
  constructor(private tokenProvider: IAuthTokenProvider) {}

  async get<T>(url: string): Promise<T> {
    const token = await this.tokenProvider.getToken();
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(`${this.baseUrl}${url}`, {
      method: 'GET',
      headers
    });

    return this.handleResponse(response);
  }

  async post<T>(url: string, data: unknown): Promise<T> {
    const token = await this.tokenProvider.getToken();
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(`${this.baseUrl}${url}`, {
      method: 'POST',
      headers,
      body: JSON.stringify(data)
    });

    return this.handleResponse(response);
  }
}
```

## UI Components

### Login Page
```typescript
// app/features/auth/pages/login.page.ts
@Component({
  selector: 'app-login',
  template: `
    <div class="login-container">
      <div class="login-card">
        <os-card>
          <os-card-header>
            <h1>OrçaSonhos</h1>
            <p>Transforme seus sonhos em metas alcançáveis</p>
          </os-card-header>
          
          <os-card-content>
            @if (authState.error()) {
              <os-alert variant="danger">
                {{ authState.error() }}
              </os-alert>
            }
            
            @if (authState.state() === 'redirecting') {
              <div class="loading-state">
                <os-spinner />
                <p>Redirecionando...</p>
              </div>
            } @else {
              <os-button 
                variant="primary"
                size="large"
                fullWidth="true"
                [loading]="authState.isLoading()"
                (onClick)="signInWithGoogle()">
                <os-icon name="google" />
                Entrar com Google
              </os-button>
            }
          </os-card-content>
        </os-card>
      </div>
    </div>
  `,
  styleUrls: ['./login.page.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class LoginPage {
  protected authState = inject(AuthStateService);

  protected async signInWithGoogle() {
    await this.authState.signInWithGoogle();
  }
}
```

### User Menu Component
```typescript
// app/shared/components/user-menu.component.ts
@Component({
  selector: 'app-user-menu',
  template: `
    @if (authState.user(); as user) {
      <os-dropdown>
        <os-button 
          slot="trigger"
          variant="tertiary"
          [attr.aria-label]="'Menu do usuário ' + user.displayName">
          <os-avatar 
            [src]="user.photoURL"
            [alt]="user.displayName"
            size="small" />
        </os-button>
        
        <os-dropdown-content>
          <os-dropdown-item>
            <os-icon name="person" />
            Perfil
          </os-dropdown-item>
          
          <os-dropdown-item>
            <os-icon name="settings" />
            Configurações  
          </os-dropdown-item>
          
          <os-dropdown-divider />
          
          <os-dropdown-item (onClick)="signOut()">
            <os-icon name="logout" />
            Sair
          </os-dropdown-item>
        </os-dropdown-content>
      </os-dropdown>
    }
  `
})
export class UserMenuComponent {
  protected authState = inject(AuthStateService);

  protected async signOut() {
    await this.authState.signOut();
  }
}
```

## Development Features

### Auth Disabled Flag
```typescript
// Para desenvolvimento sem Firebase
// environment.ts
export const environment = {
  flags: {
    authDisabled: true // Bypass auth completamente
  }
};

// Mock Auth Service para desenvolvimento
@Injectable()
export class MockAuthService implements IAuthService {
  async signInWithGoogle(): Promise<Either<AuthError, void>> {
    return Either.success(undefined);
  }

  async getCurrentUser(): Promise<Either<AuthError, AuthUser | null>> {
    return Either.success({
      uid: 'mock-user-123',
      email: 'dev@orcasonhos.com',
      displayName: 'Dev User',
      photoURL: null,
      emailVerified: true
    });
  }

  async getAccessToken(): Promise<Either<AuthError, string | null>> {
    return Either.success('mock-token-12345');
  }
}
```

## Error Handling

### Auth Error Types
```typescript
// application/errors/AuthError.ts
export class AuthError extends BaseError {
  constructor(message: string, code?: string) {
    super(message, code || 'AUTH_ERROR');
  }
}

export class TokenExpiredError extends AuthError {
  constructor() {
    super('Authentication token has expired', 'TOKEN_EXPIRED');
  }
}

export class UnauthorizedError extends AuthError {
  constructor(operation?: string) {
    super(
      `Unauthorized${operation ? ` to ${operation}` : ''}`,
      'UNAUTHORIZED'
    );
  }
}
```

### Error Recovery
```typescript
// Automatic token refresh and error recovery
export class AuthRecoveryService {
  constructor(private authState: AuthStateService) {}

  async handleAuthError(error: AuthError): Promise<boolean> {
    if (error instanceof TokenExpiredError) {
      // Tentar renovar token
      return this.attemptTokenRefresh();
    }
    
    if (error instanceof UnauthorizedError) {
      // Forçar reautenticação
      this.authState.signOut();
      return false;
    }
    
    return false;
  }

  private async attemptTokenRefresh(): Promise<boolean> {
    try {
      const user = auth.currentUser;
      if (user) {
        await user.getIdToken(true); // Force refresh
        return true;
      }
    } catch (error) {
      console.error('Token refresh failed:', error);
    }
    
    return false;
  }
}
```

---

**Ver também:**
- [Backend Integration](./backend-integration.md) - Como tokens são enviados e validados
- [Offline Strategy](./offline-strategy.md) - Autenticação em modo offline
- [Environment Configuration](./environment-configuration.md) - Feature flags e configurações