abstract final class ProductAuthorityContract {
  static const currentVersion = '1';
  static const versionLabel = '권한 계약 버전';
  static const versionLine = '$versionLabel: $currentVersion';
  static const maximumDocumentBytes = 256 * 1024;

  static const requiredSections = <String>[
    '## 저장소 정체성과 경계',
    '## 사용자 권한',
    '## 상시 역할과 변경 권한',
    '## Agreement 규칙',
    '## 실행 프로필 고정 및 편차 중단',
    '## 수행 역량 등급',
    '## 표준 작업 순환',
    '## 범위와 변경 규칙',
    '## 검증 정책',
    '## Git 정책',
    '## 보고 요구사항',
    '## 문서 언어',
    '## 제품 문맥 유지',
  ];

  static const requiredMarkers = <String>[
    'Direct Approval Actions',
    'Direct Executor',
    'Approved Execution Profile',
    'Planned Actual Execution',
    'Approved Operational Baseline Handoff',
  ];
}
