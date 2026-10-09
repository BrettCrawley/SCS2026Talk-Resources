# The assistant did something wrong

Usually a bad reply, an unexpected write, or a mail nobody meant to send.

1. Get the conversation ID from the user. It is in the console URL.
2. Pull the conversation:

   ```
   kubectl exec -it deploy/assistant-svc -- \
     curl -s localhost:8080/internal/debug/conversations/$CONVERSATION_ID | jq
   ```

   This returns the full state including everything retrieved into context. It is
   the only way to see what the model was actually working from, because tool
   arguments and results are logged at debug and production runs at info.

3. If a write went out, the target system's own audit log has it. Ours has the
   tool name and the time, not the arguments.
4. If it needs to stop now, scale the deployment to zero. There is no kill switch.
