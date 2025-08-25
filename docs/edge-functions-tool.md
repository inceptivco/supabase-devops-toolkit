# Edge Function Management Tool (`pull_edge_functions.sh`)

Download and manage Supabase Edge Functions from remote projects with secret template generation.

## 🚀 Features

- **Function Download**: Pull edge functions from remote Supabase projects
- **Secret Management**: Generate `.env.example` templates from project secrets
- **Flexible Output**: Specify custom output directories
- **Selective Download**: Download specific functions by name
- **Overwrite Protection**: Safe overwrite options with confirmation
- **Robust Parsing**: Handles both JSON and table output formats
- **Function Discovery**: Lists all available functions in a project

## 📖 Usage

### Basic Commands

```bash
# Download all edge functions from a project
./pull_edge_functions.sh --project-ref <PROJECT_REF>

# Download specific functions
./pull_edge_functions.sh --project-ref <PROJECT_REF> --names auth,webhook

# Download with secret templates
./pull_edge_functions.sh --project-ref <PROJECT_REF> --export-secrets

# Download to custom directory
./pull_edge_functions.sh --project-ref <PROJECT_REF> --outdir ./my-functions
```

### Advanced Usage

#### Function Discovery

```bash
# List all functions in a project (without downloading)
./pull_edge_functions.sh --project-ref <PROJECT_REF> --debug

# The script will show available functions before downloading
```

#### Selective Download

```bash
# Download only specific functions
./pull_edge_functions.sh --project-ref <PROJECT_REF> --names auth,webhook,api

# Download with overwrite protection
./pull_edge_functions.sh --project-ref <PROJECT_REF> --overwrite

# Non-interactive mode
./pull_edge_functions.sh --project-ref <PROJECT_REF> --yes
```

#### Secret Management

```bash
# Download functions and generate secret templates
./pull_edge_functions.sh --project-ref <PROJECT_REF> --export-secrets

# This creates:
# - .env.example in the root directory
# - .env.example in each function directory
```

#### Custom Output

```bash
# Download to a custom directory
./pull_edge_functions.sh --project-ref <PROJECT_REF> --outdir ./functions

# Download to a subdirectory
./pull_edge_functions.sh --project-ref <PROJECT_REF> --outdir ./supabase/edge-functions
```

## ⚙️ Configuration Options

| Flag | Description | Default |
|------|-------------|---------|
| `--project-ref` | Supabase project reference ID | Required |
| `--outdir` | Output directory for functions | `supabase/functions` |
| `--names` | Comma-separated list of function names | All functions |
| `--overwrite` | Overwrite existing function directories | `false` |
| `--yes` | Non-interactive mode (skip confirmations) | `false` |
| `--export-secrets` | Generate `.env.example` from project secrets | `false` |
| `--debug` | Enable debug output | `false` |

## 🔧 Smart Features

### Robust Parsing

The script handles different output formats from the Supabase CLI:
- **JSON Output**: Preferred format with structured data
- **Table Output**: Fallback format with robust parsing
- **Error Handling**: Graceful handling of API errors

### Secret Template Generation

When using `--export-secrets`:
1. Fetches all secrets from the project
2. Creates `.env.example` with secret keys (no values)
3. Copies template to each function directory
4. Provides clear documentation about secret usage

### Function Discovery

The script automatically:
1. Lists all available functions in the project
2. Shows function names before downloading
3. Handles empty function lists gracefully
4. Provides clear feedback about the download process

### Safe Operations

- **Overwrite Protection**: Confirms before overwriting existing directories
- **Directory Creation**: Automatically creates output directories
- **Error Handling**: Graceful handling of network and API errors
- **Validation**: Validates project reference and function names

## 📝 Examples

### Development Setup

```bash
# Download all functions for local development
./pull_edge_functions.sh --project-ref abcdefghijklmnop --export-secrets

# This creates:
# supabase/functions/
# ├── auth/
# │   ├── index.ts
# │   └── .env.example
# ├── webhook/
# │   ├── index.ts
# │   └── .env.example
# └── api/
#     ├── index.ts
#     └── .env.example
# .env.example (root)
```

### Selective Development

```bash
# Download only specific functions
./pull_edge_functions.sh --project-ref abcdefghijklmnop --names auth,webhook

# Download to custom location
./pull_edge_functions.sh --project-ref abcdefghijklmnop --outdir ./src/functions
```

### Production Workflow

```bash
# 1. Download functions from staging
./pull_edge_functions.sh --project-ref staging-ref --export-secrets

# 2. Review and modify functions

# 3. Deploy to production
supabase functions deploy --project-ref production-ref
```

### Team Collaboration

```bash
# Download functions with secrets template
./pull_edge_functions.sh --project-ref abcdefghijklmnop --export-secrets --yes

# Team members can then:
# 1. Copy .env.example to .env
# 2. Fill in their local secret values
# 3. Start development
```

## 🛠️ Troubleshooting

### Common Issues

1. **Missing Dependencies**
   ```bash
   # Install Supabase CLI
   npm install -g supabase
   
   # Install jq for enhanced JSON parsing (optional)
   brew install jq
   ```

2. **Permission Issues**
   ```bash
   # Make script executable
   chmod +x pull_edge_functions.sh
   ```

3. **Project Reference Issues**
   - Verify project reference is correct
   - Ensure you have access to the project
   - Check Supabase CLI authentication

4. **Function Download Failures**
   - Check network connectivity
   - Verify function names are correct
   - Use `--debug` flag for detailed output

### Debug Mode

For troubleshooting, enable debug mode:

```bash
./pull_edge_functions.sh --project-ref <REF> --debug
```

This will show:
- Raw API responses
- Parsing details
- Function discovery process
- Error details

### Common Error Messages

- **"No functions found"**: Project has no edge functions
- **"Cannot list functions"**: API access or authentication issue
- **"Function not found"**: Specified function doesn't exist
- **"Permission denied"**: Output directory access issue

## 🔒 Security Considerations

- **Secret Templates**: `.env.example` files contain only keys, not values
- **Project Access**: Ensure proper authentication and permissions
- **Local Secrets**: Never commit `.env` files with actual secret values
- **Function Code**: Review downloaded function code for security issues

## 📁 Output Structure

The script creates the following structure:

```
output-directory/
├── function1/
│   ├── index.ts          # Function code
│   ├── package.json      # Dependencies (if any)
│   └── .env.example      # Secret template (if --export-secrets)
├── function2/
│   ├── index.ts
│   └── .env.example
└── .env.example          # Root secret template (if --export-secrets)
```

## 🔄 Integration with Supabase CLI

This tool complements the Supabase CLI:

```bash
# Download functions
./pull_edge_functions.sh --project-ref <REF>

# Deploy functions back
supabase functions deploy --project-ref <REF>

# Link project for development
supabase link --project-ref <REF>
```

## 📋 Requirements

- **Supabase CLI**: [Installation Guide](https://supabase.com/docs/guides/cli)
- **Bash**: Unix-like shell environment
- **jq** (optional): For enhanced JSON parsing
- **Network Access**: To Supabase API endpoints
