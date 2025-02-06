{ lib, fetchFromGitHub, python3Packages, installShellFiles, }:

with python3Packages;

buildPythonApplication rec {
  pname = "oci-cli";
  version = "3.51.6";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "oracle";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-HRH+bt5NeZNGMpQH7dLc/F68/QCiiX9GpuPrOarxVMw=";
  };

  nativeBuildInputs = [ installShellFiles ];

  propagatedBuildInputs = [
    arrow
    certifi
    click
    cryptography
    jmespath
    oci
    prompt-toolkit
    pyopenssl
    python-dateutil
    pytz
    pyyaml
    retrying
    six
    terminaltables
  ];

  postPatch = ''
    substituteInPlace setup.py \
      --replace "cryptography>=3.2.1,<=37.0.2" "cryptography" \
      --replace "pyOpenSSL>=17.5.0,<=22.0.0" "pyOpenSSL" \
      --replace "PyYAML>=5.4,<6" "PyYAML" \
      --replace "prompt-toolkit==3.0.29" "prompt-toolkit" \
      --replace "terminaltables==3.1.10" "terminaltables" \
      --replace "oci==2.78.0" "oci"
  '';

  postInstall = ''
    cat >oci.zsh <<EOF
    #compdef oci
    zmodload -i zsh/parameter
    autoload -U +X bashcompinit && bashcompinit
    if ! (( $+functions[compdef] )) ; then
        autoload -U +X compinit && compinit
    fi

    EOF
    cat src/oci_cli/bin/oci_autocomplete.sh >>oci.zsh

    installShellCompletion \
      --cmd oci \
      --bash src/oci_cli/bin/oci_autocomplete.sh \
      --zsh oci.zsh
  '';

  # https://github.com/oracle/oci-cli/issues/187
  doCheck = false;

  pythonImportsCheck = [ " oci_cli " ];

  meta = with lib; {
    description = "Command Line Interface for Oracle Cloud Infrastructure";
    homepage =
      "https://docs.cloud.oracle.com/iaas/Content/API/Concepts/cliconcepts.htm";
    license = with licenses; [
      asl20 # or
      upl
    ];
  };
}
