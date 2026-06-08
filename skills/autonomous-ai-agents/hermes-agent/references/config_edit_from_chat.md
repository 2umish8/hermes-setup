# Editing Configuration from Chat

Mira (and any other profile) can modify its `config.yaml` or `.env` file from the chat interface as long as the **system prompt** does not prevent modifications. The following steps describe the safest way to do this:

1. **Trigger an editable tool** – `hermes config edit` is a command that opens the config in an Editor.
   - Inside the agent's interactive thread you can ask *"Open config for editing"*; the bot will respond with `hermes config edit`.
   - The command uses `$EDITOR` or falls back to `nano` if no editor is set.

2. **Change the desired values** – right after the user modifies the file, the agent will read it back on the next turn. No additional command is required; the next turn will pick up the new defaults.

3. **Validate the new configuration** – use `hermes doctor` or `hermes config check` to ensure all fields are syntactically correct.

4. **Persist changes** – once the file is written, the changes are kept for all subsequent sessions. If you want to roll back, simply edit the file again.

**Common pitfalls**:
- Editing the file from inside a `sandboxed` or `restricted` toolset may ignore the change; ensure the conversation is using a full‑toolset profile (e.g., `—profile mira`).
- Changing `model.default` to a provider that the session does not have valid API keys for will result in a *"No remote provider available"* error. Use `hermes config set default-provider <provider-name>` and provide the API key via `.env` or the credentials UI.
- Avoid editing the file with Octave‑style comments (`#!`); use `.yaml` syntax only. Aurora will refuse to parse the file.

Use this reference when you want to enable or revert configuration changes across different profiles.
