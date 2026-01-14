# Authenticating with multiple accounts on the same devicve 
Host github-egb
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github_egb
  IdentitiesOnly yes

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github_work
  IdentitiesOnly yes
