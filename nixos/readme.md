Rebuild with http proxy to workaround for JetBrains export control:

```bash
sudo HTTP_PROXY=localhost:20171 HTTPS_PROXY=localhost:20171 nixos-rebuild switch
```
