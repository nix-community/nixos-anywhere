# Adapted from https://github.com/edolstra/flake-compat/blob/master/default.nix
#
# This version only gives back the inputs. In that mode, flake becomes little
# more than a niv replacement.
{ src ? ./. }:
let
  lockFilePath = src + "/flake.lock";

  lockFile = builtins.fromJSON (builtins.readFile lockFilePath);

  # Emulate builtins.fetchTree
  #
  # TODO: only implement polyfill if the builtin doesn't exist?
  fetchTree =
    info:
    if info.type == "github" then
      {
        outPath = fetchTarball {
          url = "https://api.${info.host or "github.com"}/repos/${info.owner}/${info.repo}/tarball/${info.rev}";
          sha256 = info.narHash;
        };
        rev = info.rev;
        shortRev = builtins.substring 0 7 info.rev;
        lastModified = info.lastModified;
        narHash = info.narHash;
      }
    else if info.type == "git" then
      {
        outPath =
          builtins.fetchGit
            ({ url = info.url; sha256 = info.narHash; }
            // (if info ? rev then { inherit (info) rev; } else { })
            // (if info ? ref then { inherit (info) ref; } else { })
            );
        lastModified = info.lastModified;
        narHash = info.narHash;
      } // (if info ? rev then {
        rev = info.rev;
        shortRev = builtins.substring 0 7 info.rev;
      } else { })
    else if info.type == "path" then
      {
        outPath = builtins.path { path = info.path; };
        narHash = info.narHash;
      }
    else if info.type == "tarball" then
      {
        outPath = fetchTarball {
          url = info.url;
          sha256 = info.narHash;
        };
        narHash = info.narHash;
      }
    else if info.type == "gitlab" then
      {
        inherit (info) rev narHash lastModified;
        outPath = fetchTarball {
          url = "https://${info.host or "gitlab.com"}/api/v4/projects/${info.owner}%2F${info.repo}/repository/archive.tar.gz?sha=${info.rev}";
          sha256 = info.narHash;
        };
        shortRev = builtins.substring 0 7 info.rev;
      }
    else
    # FIXME: add Mercurial, tarball inputs.
      throw "flake input has unsupported input type '${info.type}'";

  allNodes =
    builtins.mapAttrs
      (key: node:
        let
          sourceInfo =
            if key == lockFile.root
            then { }
            else fetchTree (node.info or { } // removeAttrs node.locked [ "dir" ]);

          inputs = builtins.mapAttrs
            (inputName: inputSpec: allNodes.${resolveInput inputSpec})
            (node.inputs or { });

          # Resolve a input spec into a node name. An input spec is
          # either a node name, or a 'follows' path from the root
          # node.
          resolveInput = inputSpec:
            if builtins.isList inputSpec
            then getInputByPath lockFile.root inputSpec
            else inputSpec;

          # Follow an input path (e.g. ["dwarffs" "nixpkgs"]) from the
          # root node, returning the final node.
          getInputByPath = nodeName: path:
            if path == [ ]
            then nodeName
            else
              getInputByPath
                # Since this could be a 'follows' input, call resolveInput.
                (resolveInput lockFile.nodes.${nodeName}.inputs.${builtins.head path})
                (builtins.tail path);

          result = sourceInfo // { inherit inputs; inherit sourceInfo; };
        in
        if node.flake or true then
          result
        else
          sourceInfo
      )
      lockFile.nodes;

  result =
    if lockFile.version >= 5 && lockFile.version <= 7
    then allNodes.${lockFile.root}.inputs
    else throw "lock file '${lockFilePath}' has unsupported version ${toString lockFile.version}";

in
result

