# 자동 승격/다운그레이드 규칙

## 승격 (더 신중하게)

| From | To | 조건 |
|------|----|------|
| ask | verify | 보안 관련 코드 변경 (IAM, SG, 인증, 암호화, 키 관리) |
| ask | mobilize | 프로덕션 배포/롤백, 데이터 삭제, 인프라 대규모 변경 |
| ask | design | 신규 기능 설계, 아키텍처 변경, 마이크로서비스 분리 |
| scan | verify | Gemini 결과에서 보안 리스크 감지 |
| design | build | Kiro 스펙에서 구현 코드가 필요한 경우 |
| verify | mobilize | 교차 검증 중 심각한 불일치 발견 |

## 다운그레이드 (더 효율적으로)

| From | To | 조건 |
|------|----|------|
| verify | scan | AWS 대량 읽기 조회 (Codex sandbox 네트워크 제한) |
| verify | ask | SSM 기반 트러블슈팅 (Slave 타임아웃 문제) |
| verify | ask | 대규모 레거시 코드베이스 탐색 (Slave 파일 구조 파악 실패) |
| design | ask | 단순 설정 변경, 설계 불필요 (Kiro 오버헤드) |
| build | craft | 스펙 불필요한 단순 코드 변경 |
| mobilize | verify | 장애가 아닌 일반 배포, 위험도 낮은 변경 |

## Fallback 규칙

- Slave 타임아웃 → Master가 ask로 fallback
- Slave 2회 연속 실패 → 해당 Slave 세션 동안 비활성화
- 전체 Slave 실패 → Master ask + 사용자에게 상황 보고
