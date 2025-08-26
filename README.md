# Supabase DevOps Toolkit

A comprehensive collection of bash scripts for managing Supabase projects across development, staging, and production environments. This toolkit provides essential tools for database management, edge function deployment, and project migration workflows.

## 🛠️ Tools Included

### 1. Database Management (`supabase_backup.sh`)
Complete database backup, restore, and migration management with smart role bootstrap functionality.

### 2. Edge Function Management (`pull_edge_functions.sh`)
Download and manage Supabase Edge Functions from remote projects with automatic file organization, path fixing, and secret template generation.

## 🚀 Quick Start

### Database Operations
```bash
# Clone production database to local development
./supabase_backup.sh clone-local --db-url <REMOTE_DB_URL>

# Backup a database
./supabase_backup.sh backup --db-url <DB_URL>

# Restore to local database
./supabase_backup.sh restore --local
```

### Edge Function Operations
```bash
# Download all edge functions from a project
./pull_edge_functions.sh --project-ref <PROJECT_REF>

# Download specific functions
./pull_edge_functions.sh --project-ref <PROJECT_REF> --names auth,webhook

# Download with secret templates
./pull_edge_functions.sh --project-ref <PROJECT_REF> --export-secrets

# Fix existing function organization
./pull_edge_functions.sh --fix-existing
```

## 📋 Requirements

- **Supabase CLI**: [Installation Guide](https://supabase.com/docs/guides/cli)
- **PostgreSQL Client (psql)**: For direct database operations
- **libpq**: PostgreSQL client library for database connectivity
- **Perl**: Included by default on macOS, required for advanced text processing
- **Bash**: Unix-like shell environment
- **jq** (optional): For enhanced JSON parsing in edge function tool

## 🏗️ Project Structure

```
supabase/
├── backups/           # Database backup files (auto-created)
│   ├── roles.sql     # Database roles
│   ├── schema.sql    # Database schema
│   └── data.sql      # Database data
├── migrations/        # Generated migrations (auto-created)
│   └── 00000000000000_roles_bootstrap.sql  # Auto-generated role bootstrap
├── functions/         # Edge functions (auto-created)
│   ├── _shared/       # Shared utilities and types
│   ├── _graphql/      # GraphQL schema and resolvers
│   ├── function1/
│   │   ├── index.ts
│   │   └── .env.example
│   └── function2/
└── seed.sql          # Generated seed file (auto-created)
```

## 📖 Detailed Documentation

### Database Management Tool

The `supabase_backup.sh` script provides comprehensive database operations:

- **Complete Database Operations**: Backup, restore, baseline, and seed generation
- **Smart Role Management**: Automatic detection and bootstrap of custom database roles
- **Local & Cloud Support**: Works with both local development and production databases
- **macOS Safe**: Optimized for macOS environments with proper dependency handling
- **Idempotent Operations**: Safe to run multiple times without conflicts

[📖 Full Database Tool Documentation](./docs/database-tool.md)

### Edge Function Management Tool

The `pull_edge_functions.sh` script manages Supabase Edge Functions:

- **Function Download**: Pull edge functions from remote Supabase projects
- **Secret Management**: Generate `.env.example` templates from project secrets
- **Flexible Output**: Specify custom output directories
- **Selective Download**: Download specific functions by name
- **Overwrite Protection**: Safe overwrite options with confirmation

[📖 Full Edge Function Tool Documentation](./docs/edge-functions-tool.md)

## 🔧 Smart Features

### Database Tool Features
- **Role Bootstrap**: Automatic detection and creation of custom roles
- **Local-Safe Mode**: Filters managed schemas for local development
- **Idempotent Operations**: Safe repeated execution
- **Transaction Safety**: All operations use proper transaction handling

### Edge Function Tool Features
- **Robust Parsing**: Handles both JSON and table output formats
- **Secret Templates**: Automatically generates `.env.example` files
- **Function Discovery**: Lists all available functions in a project
- **Flexible Deployment**: Supports custom output directories
- **Path Organization**: Automatically fixes absolute paths and organizes files into `_shared` and `_graphql` directories
- **Import Fixing**: Updates TypeScript import statements to use relative paths
- **Existing Function Fixes**: Use `--fix-existing` to reorganize already downloaded functions

## 📝 Common Workflows

### Development Environment Setup
```bash
# 1. Clone production database to local
./supabase_backup.sh clone-local --db-url $PROD_DB_URL --yes

# 2. Download edge functions with automatic organization
./pull_edge_functions.sh --project-ref $PROJECT_REF --export-secrets

# 3. Start local development
supabase start
```

### Production Deployment
```bash
# 1. Backup current production database
./supabase_backup.sh backup --db-url $PROD_DB_URL

# 2. Deploy edge functions (with organized structure)
supabase functions deploy --project-ref $PROJECT_REF

# 3. Apply database migrations
supabase db push --project-ref $PROJECT_REF
```

### Staging Environment
```bash
# 1. Restore production backup to staging
./supabase_backup.sh restore --target-db-url $STAGING_DB_URL

# 2. Deploy edge functions to staging
supabase functions deploy --project-ref $STAGING_PROJECT_REF
```

## 🛠️ Troubleshooting

### Common Issues

1. **Missing Dependencies**
   ```bash
   # Install Supabase CLI
   npm install -g supabase
   
   # Install PostgreSQL client and libpq (macOS)
   brew install postgresql
   
   # Install jq for enhanced JSON parsing (optional)
   brew install jq
   ```

2. **Permission Issues**
   ```bash
   # Make scripts executable
   chmod +x supabase_backup.sh pull_edge_functions.sh
   ```

3. **Database Connection Issues**
   - Verify database URL format: `postgresql://user:pass@host:port/db`
   - Check network connectivity
   - Ensure database is accessible

### Debug Mode

For troubleshooting, you can run scripts with bash debugging:

```bash
# Database tool debugging
bash -x ./supabase_backup.sh <command> [options]

# Edge function tool debugging
bash -x ./pull_edge_functions.sh --project-ref <REF> --debug
```

## 🔒 Security Considerations

- **Database URLs**: Never commit database URLs with credentials to version control
- **Seed Files**: Add `supabase/seed.sql` to `.gitignore` if it contains sensitive data
- **Backup Files**: Consider encrypting backup files for sensitive data
- **Secret Templates**: `.env.example` files contain only keys, not values
- **Role Permissions**: Review custom roles and their permissions before bootstrap

## 📁 File Organization

### Edge Function Structure

The edge function tool automatically organizes downloaded functions into a clean structure:

```
supabase/functions/
├── _shared/           # Shared utilities, types, and common code
│   ├── types.ts       # Common TypeScript types
│   ├── utils.ts       # Shared utility functions
│   └── constants.ts   # Shared constants
├── _graphql/          # GraphQL schema and resolvers
│   ├── schema.ts      # GraphQL schema definitions
│   └── resolvers.ts   # GraphQL resolvers
├── auth/              # Authentication functions
│   ├── index.ts
│   └── .env.example
├── webhook/           # Webhook handlers
│   ├── index.ts
│   └── .env.example
└── api/               # API endpoints
    ├── index.ts
    └── .env.example
```

### Automatic Path Fixing

The tool automatically:
- **Fixes Absolute Paths**: Converts `file:/absolute/path` references to relative paths
- **Organizes Shared Code**: Moves common utilities to `_shared` directory
- **Groups GraphQL Code**: Organizes GraphQL-related files in `_graphql` directory
- **Updates Imports**: Fixes TypeScript import statements to use relative paths
- **Maintains Structure**: Preserves function-specific code in individual directories

### Fixing Existing Functions

If you have existing functions with path issues:

```bash
# Fix organization in existing functions
./pull_edge_functions.sh --fix-existing

# Fix with custom output directory
./pull_edge_functions.sh --fix-existing --outdir ./my-functions
```

## 🤝 Contributing

This toolkit is designed to be portable and maintainable. When contributing:

1. Test on both macOS and Linux environments
2. Ensure all operations remain idempotent
3. Add appropriate error handling
4. Update documentation for new features
5. Follow the existing code style and patterns

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

**Note**: These tools are designed for development and staging environments. For production backups, consider using Supabase's built-in backup features or database-specific backup solutions.
