# Rotate connector credentials

All five connectors authenticate with the app registration created for the
prototype. Rotating means rotating one secret per connector in Secrets Manager
and restarting `assistant-connectors`.

There is no per-user credential to revoke. If a specific user needs their access
to the assistant removed, remove them from the workspace team list; the
credential itself is shared and stays in place.
