# DR-001 — AI 역할 인계

상태: 승인됨

## 결정

Architecture Role은 초기 기획, 문서, 아키텍처, AI 운영 규칙을 만들고 Foundation 완료 후 일상 개발 책임을 Implementation Role에 인계한다.

Design Role은 디자인 권한을 가진다.

Implementation Role은 구현과 문서 동기화를 담당한다.

QA Role은 구현과 분리된 관점에서 검증을 수행한다.

## 이유

이전 작업에서는 중요한 판단 일부가 대화 맥락에 남아 있어 특정 Provider의 지속 개입이 필요했다. 이번 프로젝트는 판단과 작업 규칙을 저장소 문서에 남겨, 특정 대화나 AI 제품에 의존하지 않는 개발 흐름을 검증한다.

## 결과

- 모든 핵심 결정은 저장소 문서에서 확인할 수 있어야 한다.
- Implementation Role은 새 작업 전 지정된 문서를 읽어야 한다.
- 구현 에이전트가 자기 작업을 같은 역할로 최종 승인하지 않는다.
- 큰 제품 또는 아키텍처 변경만 Architecture Role 또는 사용자 판단으로 다시 올린다.
