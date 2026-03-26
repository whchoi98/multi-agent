# AWS 컨벤션 정책

## 리소스 네이밍

```
{project}-{env}-{service}-{component}
예: imweb-prod-api-ecs, imweb-staging-auth-lambda
```

## 태그 필수 항목

| 태그 | 예시 |
|------|------|
| `Environment` | prod / staging / dev |
| `Team` | infra / foundation / crm |
| `ManagedBy` | terraform / manual |
| `Service` | api / auth / event |

## 리전

- 기본 리전: `ap-northeast-2` (서울)
- DR 리전: `ap-northeast-1` (도쿄)

## 프로파일

- `sso-prod`: 프로덕션 계정
- `sso-staging`: 스테이징 계정
- `sso-dev`: 개발 계정
