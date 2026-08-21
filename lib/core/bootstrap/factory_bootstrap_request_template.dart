final class FactoryBootstrapRequestTemplate {
  const FactoryBootstrapRequestTemplate();

  String render() {
    return '''# 이 예시는 그대로 실행하지 말고 모든 예시값을 실제 값으로 바꾼다.
# 기존 빈 Repository를 사용할 때는 repositoryMode를
# existingEmptyRepository로 바꾸고 initialBranchName을 null로 설정하며
# repositoryPolicy에 기존 Repository 정책을 적는다.
schemaVersion: 1
requestId: 반드시-고유한-요청-식별자로-수정

bootstrap:
  productDisplayName: 반드시 실제 제품 이름으로 수정
  productPurpose: 반드시 실제 제품 목적으로 수정
  initialProductScopeOrFirstIntendedOutcome: 반드시 첫 결과로 수정
  exactOutputPath: /반드시/수정할/절대/제품/경로
  repositoryMode: newRepository
  initialBranchName: main
  repositoryPolicy: null
  flutterProjectName: 반드시_유효한_flutter_이름으로_수정
  organizationIdentifier: com.example
  requestedTechnology: flutter
  targetPlatforms:
    - ios
    - android
''';
  }
}
