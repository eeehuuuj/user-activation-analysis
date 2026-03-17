/*
File : 03_feature_dataset.sql

Description : 
파생 피처 통합 테이블 생성
*/

CREATE TABLE user_activation_feature_set AS
SELECT
  f.user_id,
  d.signup_time,
  d.first_enter_lesson_time,
  
  -- 레슨 진입 속도
  f.signup_to_enter_lesson_page_delay,

  -- 첫 레슨 난이도
  d.content_id AS first_content_id,
  d.content_difficulty AS first_content_difficulty,

  -- 콘텐츠 페이지 선탐색 여부
  e.is_enter_content_page_before_first_lesson,

  -- 콘텐츠 페이지 방문 수(총, 고유)
  c.content_page_total_visit,
  c.content_page_unique_visit,

  -- 후기 버튼 클릭 여부
  r.clicked_review_button,

  -- Activation 전환 여부
  CASE 
    WHEN a.user_id IS NOT NULL THEN 1
    ELSE 0
  END AS is_activated,
  a.activation_time

FROM feat_first_lesson_speed f
LEFT JOIN feat_first_lesson_difficulty d ON f.user_id = d.user_id
LEFT JOIN feat_enter_content_before_first_lesson e ON f.user_id = e.user_id
LEFT JOIN feat_content_page_count c ON f.user_id = c.user_id
LEFT JOIN feat_click_review_button r ON f.user_id = r.user_id
LEFT JOIN (
  SELECT user_id, MIN(event_time) AS activation_time
  FROM BASE_complete_lesson
  GROUP BY user_id
) a ON f.user_id = a.user_id;