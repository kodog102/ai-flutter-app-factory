# SETUP.md

> AI가 재현 가능한 Flutter 개발환경을 구성하기 위한 정책  
> Policy for AI-assisted, reproducible Flutter environment setup

## 원칙 / Principles

- FVM으로 Flutter 버전을 고정한다.
- 프로젝트 시작 시 stable channel의 호환 상태를 확인한다.
- 설치 명령을 실행하기 전 현재 상태를 먼저 진단한다.
- 이미 설치된 정상 도구를 불필요하게 재설치하지 않는다.
- 시스템 전체 설정 변경은 이유를 설명한다.
- 로그인, 라이선스, 관리자 권한, Apple 서명은 사용자 승인이 필요할 수 있다.
- 환경 구축 완료 전에 앱 기능 구현을 시작하지 않는다.

## 구현 환경 구축 절차 / Implementation Setup Procedure

1. macOS 및 CPU 아키텍처 확인
2. Homebrew 상태 확인
3. Git 확인
4. Xcode 및 Command Line Tools 확인
5. CocoaPods 필요 여부 확인
6. Android Studio 또는 Android SDK 확인
7. Java 호환 상태 확인
8. FVM 확인 및 설치
9. Flutter stable 설치 및 프로젝트 버전 고정
10. `flutter doctor -v`
11. 해결 가능한 오류 수정
12. 사용자 조치가 필요한 항목 분리 보고
13. iOS 시뮬레이터 확인
14. Android 에뮬레이터 또는 기기 확인
15. Flutter 프로젝트 생성
16. 기본 실행, 분석, 테스트

## 완료 기준 / Definition of Done

다음 결과를 기록한다.

- Flutter 버전
- Dart 버전
- Xcode 상태
- Android toolchain 상태
- 사용 가능한 디바이스
- `flutter doctor -v` 요약
- `flutter analyze`
- `flutter test`
- iOS 실행 결과
- Android 실행 결과
- 사용자가 직접 해야 하는 남은 조치

## 금지 사항 / Restrictions

- 보안 설정을 임의로 약화하지 않는다.
- 인증서 또는 비밀키를 저장소에 추가하지 않는다.
- Apple ID, keystore 비밀번호, API key를 문서에 기록하지 않는다.
- 문제를 숨긴 채 다음 단계로 넘어가지 않는다.
