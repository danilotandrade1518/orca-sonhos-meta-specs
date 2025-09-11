# Validation Rules - Regras de Validação

## 📋 Validações e Constraints

### Boundary Rules (ESLint)

```javascript
// eslint.config.js
module.exports = {
  extends: [
    '@typescript-eslint/recommended',
    '@angular-eslint/recommended'
  ],
  rules: {
    // Import restrictions para manter boundaries arquiteturais
    'import/no-restricted-paths': [
      'error',
      {
        zones: [
          // Models layer não pode importar de Application
          {
            target: './src/models',
            from: './src/application',
            message: 'Models layer cannot import from Application layer'
          },
          
          // Models layer não pode importar de Infrastructure
          {
            target: './src/models', 
            from: './src/infra',
            message: 'Models layer cannot import from Infrastructure layer'
          },
          
          // Models layer não pode importar de UI
          {
            target: './src/models',
            from: './src/app',
            message: 'Models layer cannot import from UI layer'
          },
          
          // Application layer não pode importar de UI
          {
            target: './src/application',
            from: './src/app',
            message: 'Application layer cannot import from UI layer'
          },
          
          // Backend: Domain não pode importar de Application
          {
            target: './src/domain',
            from: './src/application',
            message: 'Domain layer cannot import from Application layer'
          },
          
          // Backend: Domain não pode importar de Infrastructure
          {
            target: './src/domain',
            from: './src/infrastructure',
            message: 'Domain layer cannot import from Infrastructure layer'
          },
          
          // Backend: Application não pode importar de API
          {
            target: './src/application',
            from: './src/api',
            message: 'Application layer cannot import from API layer'
          }
        ]
      }
    ],
    
    // Naming conventions
    '@typescript-eslint/naming-convention': [
      'error',
      {
        selector: 'interface',
        format: ['PascalCase'],
        prefix: ['I']
      },
      {
        selector: 'class',
        format: ['PascalCase']
      },
      {
        selector: 'method',
        format: ['camelCase']
      },
      {
        selector: 'variable',
        format: ['camelCase', 'UPPER_CASE']
      },
      {
        selector: 'parameter',
        format: ['camelCase']
      }
    ],
    
    // Code quality
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/explicit-function-return-type': 'error',
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/prefer-readonly': 'error',
    
    // Angular specific
    '@angular-eslint/component-selector': [
      'error',
      {
        type: 'element',
        prefix: 'os',
        style: 'kebab-case'
      }
    ],
    
    // Security
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-new-func': 'error',
    'no-script-url': 'error'
  ],
  
  // Override rules for specific patterns
  overrides: [
    {
      files: ['*.spec.ts', '*.test.ts'],
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
        '@typescript-eslint/no-non-null-assertion': 'off'
      }
    },
    {
      files: ['*.factory.ts', '*.builder.ts'],
      rules: {
        '@typescript-eslint/explicit-function-return-type': 'off'
      }
    }
  ]
};
```

### TypeScript Strict Mode Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "node",
    "lib": ["ES2022", "DOM"],
    
    // Strict Type Checking
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "exactOptionalPropertyTypes": true,
    
    // Additional Checks
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    
    // Module Resolution
    "baseUrl": "./src",
    "paths": {
      "@domain/*": ["domain/*"],
      "@application/*": ["application/*"],
      "@infra/*": ["infra/*"],
      "@app/*": ["app/*"]
    },
    
    // Emit
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "removeComments": true,
    "importHelpers": true,
    
    // Interop Constraints  
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    
    // Skip type checking for libraries
    "skipLibCheck": true
  },
  
  "angularCompilerOptions": {
    "enableI18nLegacyMessageIdFormat": false,
    "strictInjectionParameters": true,
    "strictInputAccessModifiers": true,
    "strictTemplates": true,
    "strictInputTypes": true
  }
}
```

### Domain Validation Rules

```typescript
// ✅ Value Object validation constraints
export class AmountConstraints {
  public static readonly MIN_CENTS = 1; // R$ 0,01
  public static readonly MAX_CENTS = 999999999; // R$ 9.999.999,99
  public static readonly MAX_REAIS = 9999999.99;
  
  public static validate(cents: number): Either<ValidationError, void> {
    if (typeof cents !== 'number' || isNaN(cents)) {
      return Either.left(new ValidationError('Amount must be a valid number'));
    }
    
    if (!Number.isInteger(cents)) {
      return Either.left(new ValidationError('Amount must be in cents (integer)'));
    }
    
    if (cents < this.MIN_CENTS) {
      return Either.left(new ValidationError(`Minimum amount is R$ ${this.MIN_CENTS / 100}`));
    }
    
    if (cents > this.MAX_CENTS) {
      return Either.left(new ValidationError(`Maximum amount is R$ ${this.MAX_CENTS / 100}`));
    }
    
    return Either.right(void 0);
  }
}

export class DescriptionConstraints {
  public static readonly MIN_LENGTH = 1;
  public static readonly MAX_LENGTH = 200;
  public static readonly FORBIDDEN_CHARS = ['<', '>', '"', "'", '&'];
  
  public static validate(description: string): Either<ValidationError, string> {
    if (typeof description !== 'string') {
      return Either.left(new ValidationError('Description must be a string'));
    }
    
    const trimmed = description.trim();
    
    if (trimmed.length < this.MIN_LENGTH) {
      return Either.left(new ValidationError('Description is required'));
    }
    
    if (trimmed.length > this.MAX_LENGTH) {
      return Either.left(new ValidationError(`Description must not exceed ${this.MAX_LENGTH} characters`));
    }
    
    // Check for forbidden characters
    const hasForbiddenChars = this.FORBIDDEN_CHARS.some(char => trimmed.includes(char));
    if (hasForbiddenChars) {
      return Either.left(new ValidationError('Description contains forbidden characters'));
    }
    
    // Check for script injection attempts
    if (this.containsScriptInjection(trimmed)) {
      return Either.left(new ValidationError('Description contains potentially dangerous content'));
    }
    
    return Either.right(trimmed);
  }
  
  private static containsScriptInjection(text: string): boolean {
    const dangerousPatterns = [
      /javascript:/i,
      /vbscript:/i,
      /onload=/i,
      /onerror=/i,
      /onclick=/i,
      /<script/i,
      /<iframe/i,
      /eval\s*\(/i
    ];
    
    return dangerousPatterns.some(pattern => pattern.test(text));
  }
}

export class BudgetConstraints {
  public static readonly NAME_MIN_LENGTH = 1;
  public static readonly NAME_MAX_LENGTH = 100;
  public static readonly MAX_ACCOUNTS_PER_BUDGET = 50;
  public static readonly MAX_CATEGORIES_PER_BUDGET = 100;
  
  public static validateName(name: string): Either<ValidationError, string> {
    if (typeof name !== 'string') {
      return Either.left(new ValidationError('Budget name must be a string'));
    }
    
    const trimmed = name.trim();
    
    if (trimmed.length < this.NAME_MIN_LENGTH) {
      return Either.left(new ValidationError('Budget name is required'));
    }
    
    if (trimmed.length > this.NAME_MAX_LENGTH) {
      return Either.left(new ValidationError(`Budget name must not exceed ${this.NAME_MAX_LENGTH} characters`));
    }
    
    return Either.right(trimmed);
  }
  
  public static validateAccountsLimit(accountCount: number): Either<ValidationError, void> {
    if (accountCount > this.MAX_ACCOUNTS_PER_BUDGET) {
      return Either.left(new ValidationError(`Budget cannot have more than ${this.MAX_ACCOUNTS_PER_BUDGET} accounts`));
    }
    
    return Either.right(void 0);
  }
}
```

### API Validation Rules

```typescript
// ✅ DTO validation with class-validator
export class CreateTransactionDto {
  @IsNumber({ maxDecimalPlaces: 0 })
  @Min(AmountConstraints.MIN_CENTS)
  @Max(AmountConstraints.MAX_CENTS)
  @ApiProperty({ 
    minimum: AmountConstraints.MIN_CENTS,
    maximum: AmountConstraints.MAX_CENTS,
    description: 'Amount in cents'
  })
  amountCents: number;
  
  @IsString()
  @Length(DescriptionConstraints.MIN_LENGTH, DescriptionConstraints.MAX_LENGTH)
  @Matches(/^[^<>"&]*$/, { message: 'Description contains forbidden characters' })
  @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
  @ApiProperty({
    minLength: DescriptionConstraints.MIN_LENGTH,
    maxLength: DescriptionConstraints.MAX_LENGTH
  })
  description: string;
  
  @IsString()
  @IsUUID(4)
  @ApiProperty({ format: 'uuid' })
  budgetId: string;
  
  @IsOptional()
  @IsString()
  @IsUUID(4)
  @ApiProperty({ format: 'uuid', required: false })
  categoryId?: string;
  
  @IsOptional()
  @IsISO8601({ strict: true })
  @Transform(({ value }) => value ? new Date(value) : new Date())
  @ApiProperty({ format: 'date-time', required: false })
  date?: Date;
}

// ✅ Custom validators
export function IsValidCurrency(validationOptions?: ValidationOptions) {
  return function (object: any, propertyName: string) {
    registerDecorator({
      name: 'isValidCurrency',
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      validator: {
        validate(value: any) {
          if (typeof value !== 'number') return false;
          
          // Check if it's a valid currency amount (max 2 decimal places)
          const cents = Math.round(value * 100);
          return cents === value * 100 && cents >= 1 && cents <= AmountConstraints.MAX_CENTS;
        },
        defaultMessage: () => 'Amount must be a valid currency value'
      }
    });
  };
}

export function IsNotInTheFuture(validationOptions?: ValidationOptions) {
  return function (object: any, propertyName: string) {
    registerDecorator({
      name: 'isNotInTheFuture',
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      validator: {
        validate(value: any) {
          if (!(value instanceof Date)) return false;
          return value.getTime() <= Date.now();
        },
        defaultMessage: () => 'Date cannot be in the future'
      }
    });
  };
}
```

### Security Validation Rules

```typescript
// ✅ Input security validation
export class SecurityValidation {
  private static readonly SQL_INJECTION_PATTERNS = [
    /('|(\\')|(;)|(\s*(union|select|insert|delete|update|drop|create|alter|exec|execute)\s+)/i,
    /((\%27)|(\')|(\\')|((\%3D)|(=))(((\%27)|(\')|(\\'))|((\%4F)|o|(\%6F))|((\%52)|r|(\%72))))/i,
    /(((\%27)|(\')|(\\'))|((\%6F)|o|(\%4F))|((\%72)|r|(\%52)))/i
  ];
  
  private static readonly XSS_PATTERNS = [
    /<script[^>]*>.*?<\/script>/gi,
    /<iframe[^>]*>.*?<\/iframe>/gi,
    /javascript:/gi,
    /vbscript:/gi,
    /onload\s*=/gi,
    /onerror\s*=/gi,
    /onclick\s*=/gi
  ];
  
  public static validateSQLInjection(input: string): Either<SecurityError, string> {
    const hasSQLInjection = this.SQL_INJECTION_PATTERNS.some(pattern => 
      pattern.test(input)
    );
    
    if (hasSQLInjection) {
      return Either.left(new SecurityError('Input contains potentially dangerous SQL patterns'));
    }
    
    return Either.right(input);
  }
  
  public static validateXSS(input: string): Either<SecurityError, string> {
    const hasXSS = this.XSS_PATTERNS.some(pattern => pattern.test(input));
    
    if (hasXSS) {
      return Either.left(new SecurityError('Input contains potentially dangerous XSS patterns'));
    }
    
    return Either.right(input);
  }
  
  public static sanitizeInput(input: string): string {
    return input
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;')
      .replace(/&/g, '&amp;')
      .trim();
  }
}

// ✅ Rate limiting validation
export class RateLimitValidation {
  private static readonly DEFAULT_WINDOW_MS = 60 * 1000; // 1 minute
  private static readonly DEFAULT_MAX_REQUESTS = 100;
  
  public static readonly ENDPOINTS_LIMITS = {
    'POST /transaction/create-transaction': { windowMs: 60000, max: 10 },
    'POST /budget/create-budget': { windowMs: 60000, max: 5 },
    'GET /transaction/:id': { windowMs: 60000, max: 200 },
    'GET /budget/:id/transactions': { windowMs: 60000, max: 100 }
  } as const;
  
  public static getLimit(endpoint: string): { windowMs: number; max: number } {
    return this.ENDPOINTS_LIMITS[endpoint as keyof typeof this.ENDPOINTS_LIMITS] || {
      windowMs: this.DEFAULT_WINDOW_MS,
      max: this.DEFAULT_MAX_REQUESTS
    };
  }
}
```

### Database Constraints

```sql
-- ✅ Database constraints para garantir integridade
-- Transactions table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  amount_cents INTEGER NOT NULL CHECK (amount_cents > 0 AND amount_cents <= 999999999),
  description VARCHAR(200) NOT NULL CHECK (length(trim(description)) > 0),
  status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'completed', 'cancelled', 'late')),
  budget_id UUID NOT NULL,
  category_id UUID,
  account_id UUID,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  -- Foreign key constraints
  CONSTRAINT fk_transactions_budget FOREIGN KEY (budget_id) REFERENCES budgets(id) ON DELETE CASCADE,
  CONSTRAINT fk_transactions_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
  CONSTRAINT fk_transactions_account FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL,
  
  -- Indexes for performance
  INDEX idx_transactions_budget_created (budget_id, created_at DESC),
  INDEX idx_transactions_status (status),
  INDEX idx_transactions_category (category_id)
);

-- Budgets table
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL CHECK (length(trim(name)) > 0),
  amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
  user_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  -- Unique constraint per user
  CONSTRAINT uk_budgets_user_name UNIQUE (user_id, name),
  
  -- Foreign key
  CONSTRAINT fk_budgets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  -- Indexes
  INDEX idx_budgets_user (user_id),
  INDEX idx_budgets_name (name)
);

-- Row Level Security (RLS)
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY transactions_user_isolation ON transactions
  USING (budget_id IN (
    SELECT id FROM budgets WHERE user_id = current_user_id()
  ));

CREATE POLICY budgets_user_isolation ON budgets
  USING (user_id = current_user_id());
```

### Configuration Validation

```typescript
// ✅ Environment configuration validation
export class ConfigValidation {
  public static validateEnvironmentConfig(): Either<ConfigError, EnvironmentConfig> {
    const config = {
      nodeEnv: process.env['NODE_ENV'],
      port: process.env['PORT'],
      databaseUrl: process.env['DATABASE_URL'],
      jwtSecret: process.env['JWT_SECRET'],
      firebaseProjectId: process.env['FIREBASE_PROJECT_ID'],
      apiBaseUrl: process.env['API_BASE_URL']
    };
    
    // Required fields
    const requiredFields = ['nodeEnv', 'databaseUrl', 'jwtSecret', 'firebaseProjectId'];
    const missingFields = requiredFields.filter(field => !config[field as keyof typeof config]);
    
    if (missingFields.length > 0) {
      return Either.left(new ConfigError(`Missing required environment variables: ${missingFields.join(', ')}`));
    }
    
    // Validate formats
    if (config.port && (isNaN(Number(config.port)) || Number(config.port) < 1000 || Number(config.port) > 65535)) {
      return Either.left(new ConfigError('PORT must be a valid port number between 1000 and 65535'));
    }
    
    if (!config.databaseUrl?.startsWith('postgres://') && !config.databaseUrl?.startsWith('postgresql://')) {
      return Either.left(new ConfigError('DATABASE_URL must be a valid PostgreSQL connection string'));
    }
    
    if (!config.jwtSecret || config.jwtSecret.length < 32) {
      return Either.left(new ConfigError('JWT_SECRET must be at least 32 characters long'));
    }
    
    return Either.right({
      nodeEnv: config.nodeEnv as 'development' | 'production' | 'test',
      port: Number(config.port) || 3000,
      databaseUrl: config.databaseUrl!,
      jwtSecret: config.jwtSecret!,
      firebaseProjectId: config.firebaseProjectId!,
      apiBaseUrl: config.apiBaseUrl || 'http://localhost:3000'
    });
  }
}

export interface EnvironmentConfig {
  nodeEnv: 'development' | 'production' | 'test';
  port: number;
  databaseUrl: string;
  jwtSecret: string;
  firebaseProjectId: string;
  apiBaseUrl: string;
}
```

---

**Regras de validação obrigatórias:**
- ✅ **ESLint boundary rules** para arquitetura
- ✅ **TypeScript strict mode** habilitado
- ✅ **Domain constraints** em Value Objects
- ✅ **DTO validation** com class-validator
- ✅ **Security validation** contra XSS/SQL injection
- ✅ **Rate limiting** configurado por endpoint
- ✅ **Database constraints** com CHECK e FK
- ✅ **Environment validation** obrigatória

**Próximo tópico:**
- **[Code Review Checklist](./code-review-checklist.md)** - Checklist de revisão