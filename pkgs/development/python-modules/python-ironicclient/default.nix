{ lib
, buildPythonPackage
, fetchPypi
, pbr
, appdirs
, cliff
, dogpile-cache
, jsonschema
, keystoneauth1
, openstacksdk
, osc-lib
, oslo-utils
, pyyaml
, requests
, stevedore
, stestr
, requests-mock
, oslotest
}:

buildPythonPackage rec {
  pname = "python-ironicclient";
  version = "5.3.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-veDhwpSXPtoi27tKI6xebH4haAeq+sUsEEk9TxQSbg4=";
  };

  propagatedBuildInputs = [
    pbr
    appdirs
    cliff
    dogpile-cache
    jsonschema
    keystoneauth1
    openstacksdk
    osc-lib
    oslo-utils
    pyyaml
    requests
    stevedore
  ];

  nativeCheckInputs = [
    stestr
    requests-mock
    oslotest
  ];

  checkPhase = ''
    stestr run
  '';

  pythonImportsCheck = [ "ironicclient" ];

  meta = with lib; {
    description = "A client for OpenStack bare metal provisioning API, includes a Python module (ironicclient) and CLI (baremetal).";
    homepage = "https://github.com/openstack/python-ironicclient";
    license = licenses.asl20;
    maintainers = teams.openstack.members;
  };
}
