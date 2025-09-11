# Fluxo de Autenticação SPA (Firebase Authentication)

## Decisão Arquitetural

Adotamos **Firebase Authentication** como provedor de identidade com fluxo **redirect-based** para SPAs. O backend permanece totalmente **stateless** em relação à sessão do usuário, recebendo apenas o **Bearer ID Token** no header `Authorization` em cada requisição autenticada.

## Motivação

1. **Simplicidade**: Firebase Auth simplifica integração e gerenciamento de usuários
2. **Redução de complexidade**: Sem necessidade de gerenciar fluxos OAuth/OIDC complexos
3. **Múltiplos provedores**: Suporte nativo a Google, email/senha e outros provedores
4. **SDK robusto**: Bibliotecas maduras para Angular e Node.js
5. **Escalabilidade**: Infraestrutura gerenciada pelo Google

## Fluxo Completo

### 1. Frontend - Autenticação
```typescript
// firebase.config.ts
import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithRedirect } from 'firebase/auth';

const firebaseConfig = {
  apiKey: process.env['FIREBASE_API_KEY'],
  authDomain: `${process.env['FIREBASE_PROJECT_ID']}.firebaseapp.com`,
  projectId: process.env['FIREBASE_PROJECT_ID'],
  appId: process.env['FIREBASE_APP_ID']
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

// Login com Google OAuth redirect
export async function loginWithGoogle() {
  const provider = new GoogleAuthProvider();
  await signInWithRedirect(auth, provider);
}
```

### 2. Frontend - Gerenciamento de Token
```typescript
// auth.service.ts
export class AuthService {
  private currentToken: string | null = null;

  constructor() {
    // Listener para mudanças de token
    onIdTokenChanged(auth, async (user) => {
      if (user) {
        this.currentToken = await user.getIdToken();
        this.setupTokenRefresh(user);
      } else {
        this.currentToken = null;
      }
    });
  }

  private setupTokenRefresh(user: User) {
    // Token é renovado automaticamente pelo Firebase SDK
    // onIdTokenChanged captura as renovações
    setInterval(async () => {
      if (user) {
        this.currentToken = await user.getIdToken(true); // Force refresh
      }
    }, 50 * 60 * 1000); // Refresh a cada 50 minutos
  }

  getAuthToken(): string | null {
    return this.currentToken;
  }

  async logout(): Promise<void> {
    await signOut(auth);
    this.currentToken = null;
  }
}
```

### 3. Frontend - HTTP Interceptor
```typescript
// auth.interceptor.ts
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private authService: AuthService) {}

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.authService.getAuthToken();
    
    if (token) {
      const authReq = req.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`
        }
      });
      return next.handle(authReq);
    }
    
    return next.handle(req);
  }
}
```

### 4. Backend - Validação do Token
```typescript
// firebase-admin.config.ts
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const adminApp = initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID!,
    privateKey: process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL!
  })
});

export const firebaseAuth = getAuth(adminApp);
```

```typescript
// firebase-auth.service.ts
export class FirebaseAuthService {
  async verifyToken(idToken: string): Promise<string> {
    try {
      const decodedToken = await firebaseAuth.verifyIdToken(idToken);
      return decodedToken.uid; // userId para o sistema
    } catch (error) {
      throw new UnauthorizedError('Invalid Firebase token');
    }
  }

  async getUserInfo(uid: string): Promise<UserInfo> {
    try {
      const userRecord = await firebaseAuth.getUser(uid);
      return {
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: userRecord.displayName,
        photoURL: userRecord.photoURL,
        emailVerified: userRecord.emailVerified,
        disabled: userRecord.disabled,
      };
    } catch (error) {
      throw new Error(`Failed to fetch user info: ${error.message}`);
    }
  }
}
```

### 5. Backend - Middleware de Autenticação
```typescript
// auth.middleware.ts
@Injectable()
export class AuthMiddleware implements NestMiddleware {
  constructor(private firebaseAuthService: FirebaseAuthService) {}

  async use(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new UnauthorizedError('Missing or invalid authorization header');
      }

      const token = authHeader.substring(7);
      const userId = await this.firebaseAuthService.verifyToken(token);
      
      // Adiciona userId ao request para uso nos controllers
      (req as any).userId = userId;
      
      next();
    } catch (error) {
      res.status(401).json({
        success: false,
        errors: [{
          code: 'AUTH_INVALID',
          message: 'Invalid or expired token'
        }],
        timestamp: new Date().toISOString()
      });
    }
  }
}
```

### 6. Backend - Endpoint /me
```typescript
// user.controller.ts
@Controller('/user')
export class UserController {
  constructor(
    private firebaseAuthService: FirebaseAuthService,
    private userService: IUserService
  ) {}

  @Get('/me')
  async getCurrentUser(@Req() req: Request): Promise<DefaultResponse<UserProfileDto>> {
    const userId = (req as any).userId;
    
    if (!userId) {
      return {
        success: true,
        data: { isAnonymous: true },
        timestamp: new Date().toISOString()
      };
    }

    try {
      // Buscar informações do Firebase
      const firebaseUser = await this.firebaseAuthService.getUserInfo(userId);
      
      // Buscar dados adicionais do sistema (se necessário)
      const systemUser = await this.userService.getUserProfile(userId);
      
      return {
        success: true,
        data: {
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
          emailVerified: firebaseUser.emailVerified,
          isAnonymous: false,
          // Dados adicionais do sistema
          preferences: systemUser?.preferences,
          createdAt: systemUser?.createdAt,
        },
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new ApplicationError('Failed to fetch user profile');
    }
  }
}
```

## Configuração de Ambiente

### Frontend Environment
```typescript
// environment.prod.ts
export const environment = {
  production: true,
  firebase: {
    apiKey: 'AIzaSyC...',
    authDomain: 'orcasonhos-prod.firebaseapp.com',
    projectId: 'orcasonhos-prod',
    appId: '1:123456789:web:abc123...'
  }
};
```

### Backend Environment Variables
```bash
# .env.production
FIREBASE_PROJECT_ID=orcasonhos-prod
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@orcasonhos-prod.iam.gserviceaccount.com
```

## Segurança e Validação

### Validações Automáticas do Firebase
- **Signature verification**: Verificação criptográfica automática
- **Issuer validation**: `https://securetoken.google.com/PROJECT_ID`
- **Audience validation**: Firebase Project ID
- **Expiration check**: Token `exp` e `nbf` claims
- **UID extraction**: Via `decodedToken.uid`

### Segurança Adicional
```typescript
// security.config.ts
export const securityConfig = {
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['https://app.orcasonhos.com'],
    credentials: true
  },
  
  rateLimit: {
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 100, // Máximo 100 requests por IP por janela
    message: 'Too many requests from this IP'
  }
};
```

### Middleware de Rate Limiting
```typescript
// rate-limit.middleware.ts
@Injectable()
export class RateLimitMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    // Implementar rate limiting específico por usuário autenticado
    const userId = (req as any).userId;
    if (userId) {
      // Rate limiting mais restritivo para usuários autenticados
      // Permite tracking de abuse patterns
    }
    next();
  }
}
```

## Logout e Limpeza

### Frontend Logout
```typescript
// auth.service.ts
export class AuthService {
  async logout(): Promise<void> {
    try {
      // 1. Logout do Firebase
      await signOut(auth);
      
      // 2. Limpar token da memória
      this.currentToken = null;
      
      // 3. Limpar dados locais (se houver)
      localStorage.removeItem('user_preferences');
      
      // 4. Redirect para página de login
      this.router.navigate(['/login']);
    } catch (error) {
      console.error('Logout error:', error);
      // Mesmo com erro, limpar estado local
      this.currentToken = null;
      this.router.navigate(['/login']);
    }
  }
}
```

### Token Expiration Handling
```typescript
// http-error.interceptor.ts
@Injectable()
export class HttpErrorInterceptor implements HttpInterceptor {
  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(req).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401) {
          // Token inválido ou expirado
          this.authService.logout();
          return throwError(() => new Error('Authentication expired'));
        }
        return throwError(() => error);
      })
    );
  }
}
```

## O que NÃO temos inicialmente

- ❌ Sessão HTTP server-side (cookies de sessão, redis)
- ❌ Endpoints `/auth/login`, `/auth/callback`, `/auth/logout` no backend
- ❌ Armazenamento de refresh token no backend
- ❌ Múltiplos provedores (apenas Google inicialmente)
- ❌ Custom claims ou roles específicas

## Monitoramento e Logs

### Métricas de Autenticação
```typescript
// auth-metrics.service.ts
@Injectable()
export class AuthMetricsService {
  constructor(private logger: Logger) {}

  logSuccessfulAuth(userId: string, userAgent: string, ip: string): void {
    this.logger.log('Successful authentication', {
      userId,
      userAgent,
      ip,
      timestamp: new Date().toISOString(),
      event: 'AUTH_SUCCESS'
    });
  }

  logFailedAuth(reason: string, userAgent: string, ip: string): void {
    this.logger.warn('Authentication failed', {
      reason,
      userAgent,
      ip,
      timestamp: new Date().toISOString(),
      event: 'AUTH_FAILED'
    });
  }

  logTokenRefresh(userId: string): void {
    this.logger.log('Token refreshed', {
      userId,
      timestamp: new Date().toISOString(),
      event: 'TOKEN_REFRESH'
    });
  }
}
```

## Evolução Futura

| Necessidade | Implementação | Notas |
|-------------|---------------|-------|
| **Múltiplos provedores** | Habilitar email/senha, Facebook | Via console Firebase |
| **Custom claims** | Firebase Admin SDK para roles | Para autorização granular |
| **Session cookies** | `createSessionCookie()` | Para maior segurança se necessário |
| **Multi-tenant** | Firebase Auth multi-tenancy | Para orçamentos isolados |

---

**Ver também:**
- [Authorization](./authorization.md) - Controle de acesso por Budget após autenticação
- [API Endpoints](./api-endpoints.md) - Como endpoints consomem informações de auth
- [Error Handling](./error-handling.md) - Tratamento de erros de autenticação