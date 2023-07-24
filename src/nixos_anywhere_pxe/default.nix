{ pkgs
, lib
, python3
, ruff
, runCommand
}:
let
  src = ../..;

  devDependencies = lib.attrValues {
    inherit (pkgs) ruff;
    inherit (python3.pkgs)
      black
      mypy
      pytest
      pytest-cov
      pytest-subprocess
      setuptools
      wheel
      ;
  };

  package = python3.pkgs.buildPythonPackage {
    name = "nixos-anywhere-pxe";
    inherit src;
    format = "pyproject";
    nativeBuildInputs = [
      python3.pkgs.setuptools
    ];
    passthru.tests = { inherit nixos-anywhere-pxe-mypy; };
    passthru.devDependencies = devDependencies;
  };

  checkPython = python3.withPackages (_ps: devDependencies);

  nixos-anywhere-pxe-mypy = runCommand "nixos-anywhere-pxe-mypy" { } ''
    cp -r ${src} ./src
    chmod +w -R ./src
    cd src
    ${checkPython}/bin/mypy .
    touch $out
  '';

in
package
