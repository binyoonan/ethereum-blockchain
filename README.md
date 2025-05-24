# 프로젝트 관리 DApp

Vue.js와 이더리움 스마트 컨트랙트를 사용하여 만든 탈중앙화 프로젝트 관리 애플리케이션입니다.

## 필요 조건

- Node.js >= 20.12.2
- npm >= 10.5.0
- MetaMask 브라우저 확장 프로그램

## 주요 기능

- 프로젝트 생성 및 관리
- 팀원에게 작업 할당
- 작업 완료 상태 추적
- 완료된 작업 검증 및 보상 분배
- 이더리움 블록체인을 통한 실시간 업데이트

## 프로젝트 구조

```
project-management-dapp/
├── src/
│   ├── components/
│   │   ├── Navbar.vue
│   │   ├── ProjectForm.vue
│   │   ├── ProjectList.vue
│   │   ├── TaskForm.vue
│   │   └── TaskList.vue
│   ├── contracts/
│   │   ├── config.js
│   │   └── ProjectManagement.sol
│   ├── App.vue
│   └── main.js
├── public/
│   └── index.html
├── .env.example
└── package.json
```

## 스마트 컨트랙트

이 프로젝트는 Solidity 스마트 컨트랙트(`ProjectManagement.sol`)를 사용하여 다음 기능을 처리합니다:
- 프로젝트 생성 및 관리 
- 작업 완료 
- 보상 분배 

### 컨트랙트 함수

- `createProject`: 팀원과 함께 새 프로젝트 생성
- `createTask`: 프로젝트에 새 작업 생성
- `completeTask`: 작업 완료 표시
- `verifyProject`: 완료된 작업 검증 및 보상 분배
- `getProjectInfo`: 프로젝트 상세 정보 조회
- `getTeamMembers`: 프로젝트 팀원 목록 조회
- `getTaskIds`: 프로젝트의 모든 작업 ID 조회
- `getTask`: 작업 상세 정보 조회

## 설치 방법

1. 의존성 패키지 설치:
```bash
npm install
```

2. MetaMask 설정:
   - MetaMask 브라우저 확장 프로그램 설치
   - 원하는 이더리움 네트워크 연결
   - 계정 가져오기 또는 생성

3. 환경 변수 설정:
   - `.env.example`을 `.env`로 복사
   - `VITE_CONTRACT_ADDRESS`를 배포된 컨트랙트 주소로 업데이트

4. 개발 서버 실행:
```bash
npm run dev
```

## 사용 방법

1. MetaMask 지갑 연결
2. 새 프로젝트 생성
3. 팀원 추가
4. 작업 생성 및 팀원에게 할당
5. 팀원이 할당된 작업 완료
6. 관리자가 완료된 작업 검증 및 보상 분배

## 라이선스

MIT

# Vue 3 + Vite

This template should help get you started developing with Vue 3 in Vite. The template uses Vue 3 `<script setup>` SFCs, check out the [script setup docs](https://v3.vuejs.org/api/sfc-script-setup.html#sfc-script-setup) to learn more.

Learn more about IDE Support for Vue in the [Vue Docs Scaling up Guide](https://vuejs.org/guide/scaling-up/tooling.html#ide-support).
