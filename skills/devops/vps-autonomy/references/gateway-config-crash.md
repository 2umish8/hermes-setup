# Gateway Crash: NoneType.get

## Symptom
Gateway fails to start or crashes immediately with this log entry:
`WARNING gateway.config: Failed to process config.yaml — falling back to .env / gateway.json values. Check /home/hermes/.hermes/config.yaml for syntax errors. Error: 'NoneType' object has no attribute 'get'`

## Root Cause
The `config.yaml` file has a top-level key (usually `gateway:`) set to `null` or empty, but the code expects it to be a mapping/dictionary. This happens if a user or an automated process partially edits the file.

## Resolution
1. **Reset to empty mapping:**
   ```bash
   hermes config set gateway '{}'
   ```
2. **Restart gateway:**
   ```bash
   hermes gateway restart
   ```

## Prevention
Avoid direct edits to `config.yaml` using `patch` or `write_file` (which are blocked anyway); always use `hermes config set`.
