# nixos-remote - install nixos everywhere via ssh

## Usage
Needs a repo with your configurations with flakes. for a minimal example checkout https://github.com/Lassulus/flakes-testing.
afterwards you can just run:
```
  ./nixos-remote root@yourip --flake github:your-user/your-repo#your-system
```
