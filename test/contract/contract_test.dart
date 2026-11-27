import 'contract_env.dart';
import 'contract_suites.dart';

/// Same suites, every implementation.
void main() {
  runContractSuites(MockEnv.new);
  runContractSuites(RestEnv.new);
}
