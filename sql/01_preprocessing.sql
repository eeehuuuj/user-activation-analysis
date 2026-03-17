/*
File: 01_preprocessing.sql

Description:
Raw event log를 분석용 BASE 테이블로 정제하는 전처리 쿼리
- 공백 문자열을 NULL로 변환
- UTC 시간은 KST로 변환
- 분석 기간 (2022-01-01 ~ 2023-12-31) 필터링
- 한국 사용자 필터링
- client_event_time -> event_time 컬럼명 변경
*/
CREATE TABLE BASE_enter_main_page AS
WITH cleaned AS (
    SELECT 
        NULLIF(TRIM(user_id), '') AS user_id,
        CONVERT_TZ(client_event_time, 'UTC', 'Asia/Seoul') AS event_time,
        NULLIF(TRIM(country), '') AS country,
        NULLIF(TRIM(device_family), '') AS device_family,
        NULLIF(TRIM(os_name), '') AS os_name,
        NULLIF(TRIM(event_type), '') AS event_type,
        NULLIF(TRIM(platform), '') AS platform
    FROM enter_main_page
)
SELECT 
    user_id,
    event_time,
    device_family,
    os_name,
    event_type,
    platform
FROM cleaned
WHERE 
    event_time >= '2022-01-01'
    AND event_time <  '2024-01-01'
    AND country = 'South Korea';