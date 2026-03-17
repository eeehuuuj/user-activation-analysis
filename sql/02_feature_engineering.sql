/*
File: 02_feature_engineering.sql

Description:
Activation 분석을 위한 사용자 행동 피처 생성
- 가입 후 첫 레슨 진입까지 소요 시간
- 첫 진입 레슨 난이도
- 후기 더보기 버튼 클릭 여부
- Activation 이전 콘텐츠 페이지 방문 수
- 첫 레슨 시작 전 콘텐츠 페이지 탐색 여부
*/

/*
============================================================
STEP 0. 유저별 가입 시간 (Base signup time table)
============================================================
*/
CREATE TEMPORARY TABLE signup_time AS
SELECT
    user_id,
    MIN(event_time) AS signup_time
FROM BASE_complete_signup
WHERE user_id IS NOT NULL
GROUP BY user_id;

/*
============================================================
STEP 1. 가입 후 첫 레슨 진입까지 소요시간(First lesson entry speed after signup)
============================================================
*/
CREATE TABLE feat_first_lesson_speed AS
SELECT
	s.user_id,
    s.signup_time,
    -- 1. 가입시간보다 이후인 레슨페이지 진입 시간만 필터링 (그 중 제일 첫번째)
    MIN(
		CASE WHEN l.event_time > s.signup_time
			THEN l.event_time
			ELSE NULL
        END
    ) AS first_enter_lesson_after_signup,
    -- 2. 시간 차 확인하기
    TIMESTAMPDIFF(
		MINUTE,
        s.signup_time,
        MIN(
			CASE WHEN l.event_time > s.signup_time
				THEN l.event_time
                ELSE NULL
			END
        )
    ) AS signup_to_enter_lesson_page_delay
FROM signup_time s
LEFT JOIN BASE_enter_lesson_page l
	ON s.user_id = l.user_id
GROUP BY s.user_id, s.signup_time;

/*
============================================================
STEP 2. 첫 진입 레슨 난이도 (First lesson difficulty)
============================================================
*/
CREATE TEMPORARY TABLE first_enter_time AS
SELECT 
  s.user_id,
  s.signup_time,
  MIN(l.event_time) AS first_enter_lesson_time
FROM signup_time s
LEFT JOIN BASE_enter_lesson_page l
  ON s.user_id = l.user_id 
  AND l.event_time > s.signup_time
  AND l.user_id IS NOT NULL
GROUP BY s.user_id, s.signup_time;

CREATE TABLE signup_after_first_enter_lesson AS
SELECT 
  f.user_id,
  f.signup_time,
  f.first_enter_lesson_time,
  (
    SELECT l2.content_id
    FROM BASE_enter_lesson_page l2
    WHERE l2.user_id = f.user_id
      AND l2.event_time = f.first_enter_lesson_time
    LIMIT 1
  ) AS content_id
FROM first_enter_time f;

-- content_id별 가장 많이 등장한 난이도를 대표 난이도로 사용
CREATE TEMPORARY TABLE content_difficulty_map AS
SELECT 
    content_id, 
    content_difficulty
FROM (
  SELECT 
    content_id,
    content_difficulty,
    COUNT(*) AS cnt,
    ROW_NUMBER() OVER (PARTITION BY content_id ORDER BY COUNT(*) DESC) AS rn
  FROM start_content
  WHERE (content_id IS NOT NULL) AND (content_difficulty IS NOT NULL)
  GROUP BY content_id, content_difficulty
) rank_
WHERE rn = 1;

CREATE TABLE feat_first_lesson_difficulty AS
SELECT l.*, d.content_difficulty
FROM signup_after_first_enter_lesson l
LEFT JOIN content_difficulty_map d
  ON l.content_id = d.content_id;

/*
============================================================
STEP 3. Activation time
============================================================
*/
CREATE TEMPORARY TABLE activation_time AS
SELECT 
  s.user_id,
  s.signup_time,
  MIN(l.event_time) AS activation_time
FROM signup_time s
LEFT JOIN BASE_complete_lesson l 
  ON s.user_id = l.user_id AND l.event_time > s.signup_time
GROUP BY s.user_id, s.signup_time;

/*
============================================================
STEP 4. 후기 더 보기 버튼 클릭 여부 (Review button click before activation)
============================================================
*/
CREATE TEMPORARY TABLE review_click_user AS
SELECT DISTINCT c.user_id
FROM click_content_page_more_review_button c
JOIN signup_time s ON c.user_id = s.user_id
LEFT JOIN activation_time a ON c.user_id = a.user_id
WHERE c.event_time > s.signup_time
  AND (a.activation_time IS NULL OR c.event_time < a.activation_time);

CREATE TABLE feat_click_review_button AS
SELECT s.user_id,
       CASE WHEN r.user_id IS NOT NULL THEN 1 ELSE 0 END AS clicked_review_button
FROM signup_time s
LEFT JOIN review_click_user r ON s.user_id = r.user_id;

/*
============================================================
STEP 5. Activation 이전 콘텐츠 페이지 방문 수 (Content page visit count before activation)
============================================================
*/
CREATE TABLE feat_content_page_count AS
SELECT
  s.user_id,
  COUNT(c.content_id) AS content_page_total_visit, -- 총 방문 수 (콘텐츠 중복 O)
  COUNT(DISTINCT c.content_id) AS content_page_unique_visit -- 고유 콘텐츠 페이지 방문 수 (콘텐츠 중복 X)
FROM signup_time s
LEFT JOIN activation_time a ON s.user_id = a.user_id
LEFT JOIN BASE_enter_content_page c 
  ON s.user_id = c.user_id 
  AND c.event_time > s.signup_time
  AND (a.activation_time IS NULL OR c.event_time < a.activation_time)
GROUP BY s.user_id;

/*
============================================================
STEP 6. 첫 레슨 시작 전 콘텐츠 페이지 탐색 여부 (explored content before first lesson)
============================================================
*/
-- 유저별 가입 이후 첫 레슨 진입 시간
CREATE TEMPORARY TABLE first_lesson_time AS
SELECT 
  l.user_id,
  MIN(l.event_time) AS first_lesson_time
FROM BASE_enter_lesson_page l
JOIN signup_time s ON l.user_id = s.user_id
WHERE l.event_time > s.signup_time
GROUP BY l.user_id;
-- 가입 이후 ~ 첫 레슨 전 콘텐츠 페이지 진입한 유저
CREATE TEMPORARY TABLE content_before_lesson AS
SELECT DISTINCT c.user_id
FROM BASE_enter_content_page c
JOIN signup_time s ON c.user_id = s.user_id
LEFT JOIN first_lesson_time f ON c.user_id = f.user_id
WHERE c.event_time > s.signup_time
  AND (f.first_lesson_time IS NULL OR c.event_time < f.first_lesson_time);

CREATE TABLE feat_enter_content_before_first_lesson AS
SELECT 
  s.user_id,
  CASE 
    WHEN cb.user_id IS NOT NULL THEN 1 -- 콘텐츠 선탐색
    WHEN e.user_id IS NULL THEN -1 -- 아무 활동 없음
    ELSE 0 -- 탐색 없이 레슨 진입
  END AS is_enter_content_page_before_first_lesson
FROM signup_time s
LEFT JOIN content_before_lesson cb ON s.user_id = cb.user_id
LEFT JOIN (
  SELECT DISTINCT user_id FROM (
    SELECT user_id FROM BASE_enter_lesson_page
    UNION
    SELECT user_id FROM BASE_enter_content_page
  ) all_logs
) e ON s.user_id = e.user_id;