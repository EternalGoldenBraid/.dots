# Authenticating with multiple accounts on the same devicve 

## Key files
```
Host github-egb
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github_egb
  IdentitiesOnly yes
```

```
Host github-work
HostName github.com
User git
IdentityFile ~/.ssh/id_ed25519_github_work
IdentitiesOnly yes
```

## With 1password

```
Host github-egb
  HostName github.com
  User git
  # IdentityFile ~/.ssh/id_ed25519_github_egb
  IdentityAgent ~/.2password/agent.sock
```
