# Security Standards - Padrões de Segurança

## 🔒 Segurança

### Validação em Value Objects

```typescript
// ✅ Validação rigorosa em Value Objects
export class Email {
  private constructor(private readonly value: string) {}
  
  public static create(value: string): Either<ValidationError, Email> {
    // 1. Null/undefined check
    if (!value) {
      return Either.left(new ValidationError('Email is required'));
    }
    
    // 2. Basic format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(value)) {
      return Either.left(new ValidationError('Invalid email format'));
    }
    
    // 3. Length validation
    if (value.length > 254) {
      return Either.left(new ValidationError('Email too long'));
    }
    
    // 4. Domain validation (additional security)
    const domain = value.split('@')[1];
    if (this.isDisallowedDomain(domain)) {
      return Either.left(new ValidationError('Email domain not allowed'));
    }
    
    // 5. Sanitization
    const sanitized = value.toLowerCase().trim();
    
    return Either.right(new Email(sanitized));
  }
  
  public getValue(): string {
    return this.value;
  }
  
  private static isDisallowedDomain(domain: string): boolean {
    const disallowedDomains = [
      'tempmail.org',
      '10minutemail.com',
      'guerrillamail.com'
      // Add more disposable email domains
    ];
    
    return disallowedDomains.some(blocked => 
      domain.toLowerCase().includes(blocked.toLowerCase())
    );
  }
}

// ✅ Money Value Object com validação
export class Money {
  private constructor(private readonly cents: number) {}
  
  public static fromCents(cents: number): Either<ValidationError, Money> {
    // 1. Type validation
    if (typeof cents !== 'number' || isNaN(cents)) {
      return Either.left(new ValidationError('Amount must be a valid number'));
    }
    
    // 2. Range validation  
    if (cents < 0) {
      return Either.left(new ValidationError('Amount cannot be negative'));
    }
    
    if (cents > 999999999) { // Max: R$ 9.999.999,99
      return Either.left(new ValidationError('Amount too large'));
    }
    
    // 3. Precision validation (cents only)
    if (!Number.isInteger(cents)) {
      return Either.left(new ValidationError('Amount must be in cents (integer)'));
    }
    
    return Either.right(new Money(cents));
  }
  
  public static fromReais(reais: number): Either<ValidationError, Money> {
    if (typeof reais !== 'number' || isNaN(reais)) {
      return Either.left(new ValidationError('Amount must be a valid number'));
    }
    
    // Convert to cents and validate precision
    const cents = Math.round(reais * 100);
    
    return Money.fromCents(cents);
  }
  
  public getCents(): number {
    return this.cents;
  }
  
  public getReais(): number {
    return this.cents / 100;
  }
  
  public isPositive(): boolean {
    return this.cents > 0;
  }
  
  public isZeroOrNegative(): boolean {
    return this.cents <= 0;
  }
}

// ✅ CPF/CNPJ validation
export class TaxId {
  private constructor(
    private readonly value: string,
    private readonly type: 'CPF' | 'CNPJ'
  ) {}
  
  public static create(value: string): Either<ValidationError, TaxId> {
    if (!value) {
      return Either.left(new ValidationError('Tax ID is required'));
    }
    
    // Remove all non-digits
    const digits = value.replace(/\D/g, '');
    
    // Determine type and validate
    if (digits.length === 11) {
      return this.validateCPF(digits).map(valid => new TaxId(valid, 'CPF'));
    } else if (digits.length === 14) {
      return this.validateCNPJ(digits).map(valid => new TaxId(valid, 'CNPJ'));
    } else {
      return Either.left(new ValidationError('Tax ID must be CPF (11 digits) or CNPJ (14 digits)'));
    }
  }
  
  private static validateCPF(cpf: string): Either<ValidationError, string> {
    // CPF validation algorithm
    if (cpf === '00000000000' || cpf === '11111111111') {
      return Either.left(new ValidationError('Invalid CPF'));
    }
    
    // Validate check digits
    let sum = 0;
    for (let i = 0; i < 9; i++) {
      sum += parseInt(cpf.charAt(i)) * (10 - i);
    }
    
    let digit = 11 - (sum % 11);
    if (digit === 10 || digit === 11) digit = 0;
    if (digit !== parseInt(cpf.charAt(9))) {
      return Either.left(new ValidationError('Invalid CPF check digit'));
    }
    
    sum = 0;
    for (let i = 0; i < 10; i++) {
      sum += parseInt(cpf.charAt(i)) * (11 - i);
    }
    
    digit = 11 - (sum % 11);
    if (digit === 10 || digit === 11) digit = 0;
    if (digit !== parseInt(cpf.charAt(10))) {
      return Either.left(new ValidationError('Invalid CPF check digit'));
    }
    
    return Either.right(cpf);
  }
  
  private static validateCNPJ(cnpj: string): Either<ValidationError, string> {
    // CNPJ validation algorithm implementation
    const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    
    // Check first digit
    let sum = 0;
    for (let i = 0; i < 12; i++) {
      sum += parseInt(cnpj.charAt(i)) * weights1[i];
    }
    
    let digit = sum % 11 < 2 ? 0 : 11 - (sum % 11);
    if (digit !== parseInt(cnpj.charAt(12))) {
      return Either.left(new ValidationError('Invalid CNPJ check digit'));
    }
    
    // Check second digit
    sum = 0;
    for (let i = 0; i < 13; i++) {
      sum += parseInt(cnpj.charAt(i)) * weights2[i];
    }
    
    digit = sum % 11 < 2 ? 0 : 11 - (sum % 11);
    if (digit !== parseInt(cnpj.charAt(13))) {
      return Either.left(new ValidationError('Invalid CNPJ check digit'));
    }
    
    return Either.right(cnpj);
  }
  
  public getValue(): string {
    return this.value;
  }
  
  public getType(): 'CPF' | 'CNPJ' {
    return this.type;
  }
  
  public getFormatted(): string {
    if (this.type === 'CPF') {
      return this.value.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
    } else {
      return this.value.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5');
    }
  }
}
```

### Input Sanitization

```typescript
// ✅ Sanitização de entrada obrigatória
export class InputSanitizer {
  public static sanitizeString(input: string): string {
    if (typeof input !== 'string') {
      return '';
    }
    
    return input
      .trim()
      // Remove script tags
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      // Remove other potentially dangerous tags
      .replace(/<(iframe|object|embed|link|meta|style)[^>]*>/gi, '')
      // Remove javascript: protocol
      .replace(/javascript:/gi, '')
      // Remove on* event handlers
      .replace(/\son\w+\s*=\s*["'][^"']*["']/gi, '')
      // Normalize whitespace
      .replace(/\s+/g, ' ');
  }
  
  public static sanitizeHtml(input: string): string {
    // Use a proper HTML sanitization library like DOMPurify for production
    const allowedTags = ['b', 'i', 'em', 'strong', 'p', 'br'];
    const allowedAttributes: string[] = [];
    
    // Basic implementation - use proper library in production
    let sanitized = input;
    
    // Remove all tags except allowed ones
    const tagRegex = /<\/?([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>/gi;
    sanitized = sanitized.replace(tagRegex, (match, tagName) => {
      return allowedTags.includes(tagName.toLowerCase()) ? match : '';
    });
    
    return sanitized;
  }
  
  public static sanitizeNumber(input: any): number | null {
    if (typeof input === 'number' && !isNaN(input)) {
      return input;
    }
    
    if (typeof input === 'string') {
      const parsed = parseFloat(input.replace(/[^\d.-]/g, ''));
      return isNaN(parsed) ? null : parsed;
    }
    
    return null;
  }
  
  public static sanitizeEmail(input: string): string {
    return this.sanitizeString(input)
      .toLowerCase()
      .replace(/[^\w@.-]/g, ''); // Keep only word chars, @, dot, hyphen
  }
  
  public static sanitizePhoneNumber(input: string): string {
    return input.replace(/[^\d+()-\s]/g, '').trim();
  }
}

// ✅ Sanitization decorator
export function Sanitize(sanitizer: (input: any) => any) {
  return function (target: any, propertyName: string, descriptor: PropertyDescriptor) {
    const method = descriptor.value;
    
    descriptor.value = function (...args: any[]) {
      const sanitizedArgs = args.map(arg => {
        if (typeof arg === 'object' && arg !== null) {
          return sanitizeObject(arg, sanitizer);
        }
        return sanitizer(arg);
      });
      
      return method.apply(this, sanitizedArgs);
    };
  };
}

function sanitizeObject(obj: any, sanitizer: (input: any) => any): any {
  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeObject(item, sanitizer));
  }
  
  if (obj && typeof obj === 'object') {
    const sanitized: any = {};
    for (const [key, value] of Object.entries(obj)) {
      sanitized[key] = sanitizeObject(value, sanitizer);
    }
    return sanitized;
  }
  
  return sanitizer(obj);
}
```

### Headers e Token Security

```typescript
// ✅ HTTP Client com headers seguros
@Injectable({ providedIn: 'root' })
export class SecureHttpClient {
  private readonly baseHeaders = {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin'
  };
  
  constructor(
    private readonly httpClient: HttpClient,
    private readonly tokenService: TokenService,
    private readonly configService: ConfigService
  ) {}
  
  async request<T>(config: SecureRequestConfig): Promise<Either<HttpError, T>> {
    try {
      // 1. Get and validate token
      const tokenResult = await this.getValidToken();
      if (tokenResult.isLeft()) {
        return Either.left(new UnauthorizedHttpError('Invalid token'));
      }
      
      // 2. Build secure headers
      const headers = {
        ...this.baseHeaders,
        'Authorization': `Bearer ${tokenResult.value}`,
        // Add CSRF protection if needed
        ...(config.csrfToken ? { 'X-CSRF-Token': config.csrfToken } : {}),
        ...config.headers
      };
      
      // 3. Validate URL
      if (!this.isAllowedUrl(config.url)) {
        return Either.left(new ForbiddenHttpError('URL not allowed'));
      }
      
      // 4. Sanitize request body
      const sanitizedBody = config.body ? this.sanitizeRequestBody(config.body) : undefined;
      
      // 5. Make request with timeout
      const response = await this.httpClient.request<T>(config.method, config.url, {
        body: sanitizedBody,
        headers,
        timeout: config.timeout || 30000,
        // IMPORTANT: Credentials only for same-origin requests
        withCredentials: this.isSameOrigin(config.url)
      }).toPromise();
      
      return Either.right(response!);
      
    } catch (error) {
      return Either.left(this.mapHttpError(error));
    }
  }
  
  private async getValidToken(): Promise<Either<TokenError, string>> {
    const token = await this.tokenService.getAccessToken();
    if (!token) {
      return Either.left(new TokenError('No token available'));
    }
    
    // Validate token format and expiration
    if (!this.isValidTokenFormat(token)) {
      return Either.left(new TokenError('Invalid token format'));
    }
    
    if (this.isTokenExpired(token)) {
      // Try to refresh
      const refreshResult = await this.tokenService.refreshToken();
      return refreshResult.fold(
        error => Either.left(new TokenError('Token expired and refresh failed')),
        newToken => Either.right(newToken)
      );
    }
    
    return Either.right(token);
  }
  
  private isAllowedUrl(url: string): boolean {
    const allowedDomains = this.configService.get<string[]>('ALLOWED_API_DOMAINS') || [];
    const apiBaseUrl = this.configService.get<string>('API_BASE_URL');
    
    // Allow relative URLs and same domain
    if (url.startsWith('/') || url.startsWith(apiBaseUrl)) {
      return true;
    }
    
    // Check allowed external domains
    try {
      const urlObj = new URL(url);
      return allowedDomains.some(domain => 
        urlObj.hostname === domain || urlObj.hostname.endsWith(`.${domain}`)
      );
    } catch {
      return false;
    }
  }
  
  private sanitizeRequestBody(body: any): any {
    if (typeof body === 'string') {
      return InputSanitizer.sanitizeString(body);
    }
    
    if (Array.isArray(body)) {
      return body.map(item => this.sanitizeRequestBody(item));
    }
    
    if (body && typeof body === 'object') {
      const sanitized: any = {};
      for (const [key, value] of Object.entries(body)) {
        sanitized[InputSanitizer.sanitizeString(key)] = this.sanitizeRequestBody(value);
      }
      return sanitized;
    }
    
    return body;
  }
  
  private isValidTokenFormat(token: string): boolean {
    // JWT token validation
    const parts = token.split('.');
    if (parts.length !== 3) {
      return false;
    }
    
    try {
      // Validate base64 encoding
      atob(parts[0]);
      atob(parts[1]);
      return true;
    } catch {
      return false;
    }
  }
  
  private isTokenExpired(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      const exp = payload.exp;
      const now = Math.floor(Date.now() / 1000);
      
      // Consider token expired 5 minutes before actual expiration
      return exp - now < 300;
    } catch {
      return true;
    }
  }
  
  private isSameOrigin(url: string): boolean {
    if (url.startsWith('/')) {
      return true;
    }
    
    try {
      const urlObj = new URL(url);
      return urlObj.origin === window.location.origin;
    } catch {
      return false;
    }
  }
}

interface SecureRequestConfig {
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  url: string;
  body?: any;
  headers?: Record<string, string>;
  timeout?: number;
  csrfToken?: string;
}
```

### Authentication & Authorization

```typescript
// ✅ JWT Token Service com segurança
@Injectable({ providedIn: 'root' })
export class SecureTokenService {
  private readonly tokenKey = 'os_access_token';
  private readonly refreshTokenKey = 'os_refresh_token';
  private readonly tokenExpBuffer = 5 * 60 * 1000; // 5 minutes
  
  constructor(
    private readonly storage: SecureStorageService,
    private readonly httpClient: HttpClient
  ) {}
  
  async getAccessToken(): Promise<string | null> {
    const token = this.storage.getItem(this.tokenKey);
    if (!token) {
      return null;
    }
    
    if (this.isTokenExpiringSoon(token)) {
      const refreshResult = await this.refreshToken();
      return refreshResult.fold(
        () => null,
        newToken => newToken
      );
    }
    
    return token;
  }
  
  async refreshToken(): Promise<Either<AuthError, string>> {
    const refreshToken = this.storage.getItem(this.refreshTokenKey);
    if (!refreshToken) {
      return Either.left(new AuthError('No refresh token available'));
    }
    
    try {
      const response = await this.httpClient.post<TokenResponse>('/auth/refresh', {
        refreshToken
      }, {
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      }).toPromise();
      
      if (!response || !response.accessToken) {
        throw new Error('Invalid refresh response');
      }
      
      // Store new tokens securely
      this.storage.setItem(this.tokenKey, response.accessToken);
      if (response.refreshToken) {
        this.storage.setItem(this.refreshTokenKey, response.refreshToken);
      }
      
      return Either.right(response.accessToken);
      
    } catch (error) {
      // Clear invalid tokens
      this.clearTokens();
      return Either.left(new AuthError('Token refresh failed'));
    }
  }
  
  setTokens(accessToken: string, refreshToken: string): void {
    // Validate tokens before storing
    if (!this.isValidJWTFormat(accessToken) || !this.isValidJWTFormat(refreshToken)) {
      throw new Error('Invalid token format');
    }
    
    this.storage.setItem(this.tokenKey, accessToken);
    this.storage.setItem(this.refreshTokenKey, refreshToken);
  }
  
  clearTokens(): void {
    this.storage.removeItem(this.tokenKey);
    this.storage.removeItem(this.refreshTokenKey);
  }
  
  private isTokenExpiringSoon(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      const exp = payload.exp * 1000; // Convert to milliseconds
      const now = Date.now();
      
      return exp - now < this.tokenExpBuffer;
    } catch {
      return true;
    }
  }
  
  private isValidJWTFormat(token: string): boolean {
    if (!token || typeof token !== 'string') {
      return false;
    }
    
    const parts = token.split('.');
    if (parts.length !== 3) {
      return false;
    }
    
    try {
      // Validate header
      const header = JSON.parse(atob(parts[0]));
      if (!header.alg || !header.typ) {
        return false;
      }
      
      // Validate payload
      const payload = JSON.parse(atob(parts[1]));
      if (!payload.exp || !payload.iat) {
        return false;
      }
      
      return true;
    } catch {
      return false;
    }
  }
}

// ✅ Secure Storage Service
@Injectable({ providedIn: 'root' })
export class SecureStorageService {
  private readonly prefix = 'os_secure_';
  
  setItem(key: string, value: string): void {
    try {
      // Use sessionStorage for sensitive tokens (cleared on tab close)
      // Use localStorage only for non-sensitive data
      const storage = this.isSensitiveKey(key) ? sessionStorage : localStorage;
      
      // Encrypt sensitive values (in production, use proper encryption)
      const encryptedValue = this.isSensitiveKey(key) 
        ? this.simpleEncrypt(value)
        : value;
      
      storage.setItem(this.prefix + key, encryptedValue);
    } catch (error) {
      console.warn('Storage not available:', error);
    }
  }
  
  getItem(key: string): string | null {
    try {
      const storage = this.isSensitiveKey(key) ? sessionStorage : localStorage;
      const value = storage.getItem(this.prefix + key);
      
      if (!value) {
        return null;
      }
      
      // Decrypt sensitive values
      return this.isSensitiveKey(key) 
        ? this.simpleDecrypt(value)
        : value;
    } catch (error) {
      console.warn('Storage read error:', error);
      return null;
    }
  }
  
  removeItem(key: string): void {
    try {
      sessionStorage.removeItem(this.prefix + key);
      localStorage.removeItem(this.prefix + key);
    } catch (error) {
      console.warn('Storage removal error:', error);
    }
  }
  
  private isSensitiveKey(key: string): boolean {
    const sensitiveKeys = ['access_token', 'refresh_token', 'user_session'];
    return sensitiveKeys.some(sensitive => key.includes(sensitive));
  }
  
  private simpleEncrypt(value: string): string {
    // PRODUCTION: Use proper encryption library like crypto-js
    return btoa(value); // Basic base64 encoding for demo
  }
  
  private simpleDecrypt(value: string): string {
    // PRODUCTION: Use proper decryption
    try {
      return atob(value);
    } catch {
      return '';
    }
  }
}

interface TokenResponse {
  accessToken: string;
  refreshToken?: string;
  expiresIn: number;
}
```

### Security Headers & CSP

```typescript
// ✅ Security middleware/interceptor
export const securityHeadersInterceptor: HttpInterceptorFn = (req, next) => {
  const secureReq = req.clone({
    setHeaders: {
      // XSS Protection
      'X-XSS-Protection': '1; mode=block',
      
      // Content Type Options
      'X-Content-Type-Options': 'nosniff',
      
      // Frame Options
      'X-Frame-Options': 'DENY',
      
      // Referrer Policy
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      
      // CSRF Protection
      'X-Requested-With': 'XMLHttpRequest'
    }
  });
  
  return next(secureReq);
};

// ✅ Content Security Policy (para index.html)
const cspDirectives = {
  'default-src': ["'self'"],
  'script-src': ["'self'", "'unsafe-inline'", 'https://apis.google.com'],
  'style-src': ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
  'font-src': ["'self'", 'https://fonts.gstatic.com'],
  'img-src': ["'self'", 'data:', 'https:'],
  'connect-src': ["'self'", 'https://api.orcasonhos.com'],
  'frame-ancestors': ["'none'"],
  'form-action': ["'self'"],
  'base-uri': ["'self'"]
};

// Meta tag no index.html:
// <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline'...">
```

---

**Práticas de segurança obrigatórias:**
- ✅ **Value Objects** com validação rigorosa
- ✅ **Input sanitization** obrigatória
- ✅ **Token security** com JWT validation
- ✅ **Secure headers** configurados
- ✅ **CSP policy** implementada
- ✅ **HTTPS-only** em produção
- ✅ **Rate limiting** configurado
- ✅ **Secure storage** para tokens

**Próximos tópicos:**
- **[Testing Standards](./testing-standards.md)** - Padrões de testes
- **[Validation Rules](./validation-rules.md)** - Regras de validação