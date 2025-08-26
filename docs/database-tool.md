# Database Management Tool (`supabase_backup.sh`)

Complete database backup, restore, and migration management with smart role bootstrap functionality.

## 🚀 Features

- **Complete Database Operations**: Backup, restore, baseline, and seed generation
- **Smart Role Management**: Automatic detection and bootstrap of custom database roles
- **Local & Cloud Support**: Works with both local development and production databases
- **macOS Safe**: Optimized for macOS environments with proper dependency handling
- **Idempotent Operations**: Safe to run multiple times without conflicts
- **Flexible Filtering**: Exclude specific schemas, tables, or data as needed
- **Archive Management**: Automatic migration archiving with optional cleanup

## 📖 Usage

### Basic Commands

```bash
# Clone a remote database to local development
./supabase_backup.sh clone-local --db-url <REMOTE_DB_URL>

# Backup a database
./supabase_backup.sh backup --db-url <DB_URL>

# Restore to local database
./supabase_backup.sh restore --local

# Restore to remote database
./supabase_backup.sh restore --target-db-url <DB_URL>

# Create baseline migration from local database
./supabase_backup.sh baseline

# Generate seed file from database
./supabase_backup.sh make-seed --db-url <DB_URL>
```

### Advanced Usage

#### Clone Local (Complete Workflow)

The `clone-local` command performs a complete workflow:
1. **Backup** the remote database
2. **Restore** to local development environment
3. **Create baseline** migration
4. **Generate seed** file
5. **Bootstrap roles** automatically

```bash
# Basic clone with automatic role detection
./supabase_backup.sh clone-local --db-url postgresql://user:pass@host:port/db

# Clone with specific roles
./supabase_backup.sh clone-local --db-url <DB_URL> --roles admin,editor,viewer

# Clone with verification
./supabase_backup.sh clone-local --db-url <DB_URL> --verify-reset

# Clone with archive preservation
./supabase_backup.sh clone-local --db-url <DB_URL> --keep-archive

# Non-interactive mode
./supabase_backup.sh clone-local --db-url <DB_URL> --yes
```

#### Backup Operations

```bash
# Basic backup
./supabase_backup.sh backup --db-url <DB_URL>

# The backup creates three files:
# - roles.sql: Database roles and permissions
# - schema.sql: Database structure (tables, views, functions, etc.)
# - data.sql: Database content
```

#### Restore Operations

```bash
# Restore to local database (recommended for development)
./supabase_backup.sh restore --local

# Restore to local with custom options
./supabase_backup.sh restore --local --no-local-safe --no-strip-owners

# Restore to remote database
./supabase_backup.sh restore --target-db-url <TARGET_DB_URL>

# Restore with custom options
./supabase_backup.sh restore --target-db-url <TARGET_DB_URL> --no-strip-grantors
```

#### Baseline Migration

```bash
# Create baseline from local database
./supabase_backup.sh baseline

# Create baseline for specific schemas
./supabase_backup.sh baseline --schemas public,auth

# Create baseline without archiving existing migrations
./supabase_backup.sh baseline --no-archive

# Create baseline and keep archive
./supabase_backup.sh baseline --keep-archive
```

#### Seed Generation

```bash
# Generate seed from database
./supabase_backup.sh make-seed --db-url <DB_URL>

# Generate seed for specific schemas
./supabase_backup.sh make-seed --db-url <DB_URL> --schemas public

# Generate seed excluding auth users
./supabase_backup.sh make-seed --db-url <DB_URL> --no-auth-users

# Generate seed excluding specific tables
./supabase_backup.sh make-seed --db-url <DB_URL> --exclude public.sensitive_table
```

## ⚙️ Configuration Options

### Global Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--yes`, `--assume-yes` | Non-interactive mode | `false` |
| `--roles r1,r2` | Force specific roles for bootstrap | `[]` |

### Restore Options

| Flag | Description | Default |
|------|-------------|---------|
| `--local` | Restore to local Supabase instance | `false` |
| `--target-db-url` | Target database URL for cloud restore | `""` |
| `--local-safe` | Enable local-safe mode (filters managed schemas) | `true` |
| `--no-local-safe` | Disable local-safe mode | - |
| `--strip-owners` | Remove OWNER TO clauses | `true` |
| `--no-strip-owners` | Preserve OWNER TO clauses | - |
| `--strip-grantors` | Remove GRANTED BY clauses | `true` |
| `--no-strip-grantors` | Preserve GRANTED BY clauses | - |

### Baseline Options

| Flag | Description | Default |
|------|-------------|---------|
| `--schemas` | Schemas to include in baseline | `public` |
| `--archive-existing` | Archive existing migrations | `true` |
| `--no-archive` | Don't archive existing migrations | - |
| `--keep-archive` | Keep archived migrations | `false` |

### Seed Options

| Flag | Description | Default |
|------|-------------|---------|
| `--schemas` | Schemas to include in seed | `public` |
| `--include-auth-users` | Include auth.users in seed | `true` |
| `--no-auth-users` | Exclude auth.users from seed | - |
| `--exclude` | Exclude specific schema.table | `[]` |

## 🔧 Smart Features

### Role Bootstrap

The script automatically detects custom roles from:
- Existing migrations
- Database grants and policies
- Forced roles via `--roles` flag

It creates a bootstrap migration (`00000000000000_roles_bootstrap.sql`) that ensures roles exist before other migrations run.

### Local-Safe Mode

When restoring to local development:
- Filters out managed Supabase schemas (`auth`, `storage`, `realtime`, etc.)
- Prevents conflicts with local Supabase instance
- Maintains data integrity

### Idempotent Operations

- **Role Creation**: Uses `DO $$BEGIN ... EXCEPTION WHEN duplicate_object THEN NULL; END$$;`
- **Sequence Values**: Safe `setval` operations with existence checks
- **Migration Archiving**: Preserves existing migrations in timestamped archives

### Data Safety

- **Transaction Safety**: All operations use `--single-transaction`
- **Error Handling**: Stops on first error with `ON_ERROR_STOP=1`
- **Replication Role**: Uses `session_replication_role = replica` for data loading
- **COPY Block Detection**: Ensures INSERT statements for transaction safety

## 📝 Examples

### Development Workflow

```bash
# 1. Clone production database to local
./supabase_backup.sh clone-local --db-url $PROD_DB_URL --yes

# 2. Make changes to local database

# 3. Create new migration
supabase db diff -f new_feature

# 4. Test with reset
supabase db reset

# 5. Deploy to production
supabase db push
```

### Production Backup

```bash
# Create backup of production database
./supabase_backup.sh backup --db-url $PROD_DB_URL

# Backup files are created in supabase/backups/
ls supabase/backups/
# roles.sql  schema.sql  data.sql
```

### Staging Setup

```bash
# Restore production backup to staging
./supabase_backup.sh restore --target-db-url $STAGING_DB_URL

# Create baseline for staging
./supabase_backup.sh baseline --schemas public,auth
```

## 📋 Requirements

- **Supabase CLI**: [Installation Guide](https://supabase.com/docs/guides/cli)
- **PostgreSQL Client (psql)**: For direct database operations
- **libpq**: PostgreSQL client library for database connectivity
- **Bash**: Unix-like shell environment
- **Perl**: Included by default on macOS, required for advanced text processing

## 🛠️ Troubleshooting

### Common Issues

1. **Missing Dependencies**
   ```bash
   # Install Supabase CLI
   npm install -g supabase
   
   # Install PostgreSQL client and libpq (macOS)
   brew install postgresql
   ```

2. **Permission Issues**
   ```bash
   # Make script executable
   chmod +x supabase_backup.sh
   ```

3. **Database Connection Issues**
   - Verify database URL format: `postgresql://user:pass@host:port/db`
   - Check network connectivity
   - Ensure database is accessible

4. **Role Bootstrap Failures**
   - Check for role name conflicts
   - Verify role permissions in source database
   - Use `--no-role-bootstrap` to skip automatic role creation

### Debug Mode

For troubleshooting, you can run the script with bash debugging:

```bash
bash -x ./supabase_backup.sh <command> [options]
```

## 🔒 Security Considerations

- **Database URLs**: Never commit database URLs with credentials to version control
- **Seed Files**: Add `supabase/seed.sql` to `.gitignore` if it contains sensitive data
- **Backup Files**: Consider encrypting backup files for sensitive data
- **Role Permissions**: Review custom roles and their permissions before bootstrap
