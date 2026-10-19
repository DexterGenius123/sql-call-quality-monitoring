-- 1. Звонки, которые ещё не проверены: очередь контроля качества.
SELECT c.call_id, m.full_name AS manager, c.started_at, c.outcome
FROM calls c
JOIN managers m ON m.manager_id = c.manager_id
LEFT JOIN quality_reviews qr ON qr.call_id = c.call_id
WHERE qr.review_id IS NULL
ORDER BY c.started_at;

-- 2. Просроченный SLA: проверка должна быть завершена за 24 часа.
SELECT c.call_id, m.full_name, c.started_at, qr.reviewed_at,
       qr.reviewed_at - c.started_at AS review_delay
FROM calls c
JOIN managers m ON m.manager_id = c.manager_id
JOIN quality_reviews qr ON qr.call_id = c.call_id
WHERE qr.reviewed_at > c.started_at + INTERVAL '24 hours'
ORDER BY review_delay DESC;

-- 3. KPI по менеджерам: средний балл, количество проверок и доля оценок >= 80.
SELECT m.full_name,
       COUNT(qr.review_id) AS reviewed_calls,
       ROUND(AVG(qr.total_score), 1) AS avg_score,
       ROUND(100.0 * AVG((qr.total_score >= 80)::INT), 1) AS pass_rate_pct
FROM managers m
LEFT JOIN calls c ON c.manager_id = m.manager_id
LEFT JOIN quality_reviews qr ON qr.call_id = c.call_id
GROUP BY m.manager_id, m.full_name
ORDER BY avg_score DESC NULLS LAST;

-- 4. Критические нарушения, требующие эскалации.
SELECT c.call_id, m.full_name, c.started_at, vt.code, vt.title
FROM review_violations rv
JOIN violation_types vt ON vt.violation_type_id = rv.violation_type_id
JOIN quality_reviews qr ON qr.review_id = rv.review_id
JOIN calls c ON c.call_id = qr.call_id
JOIN managers m ON m.manager_id = c.manager_id
WHERE vt.severity = 'critical'
ORDER BY c.started_at DESC;

-- 5. Дневная динамика: объём звонков и конверсия в продажу.
SELECT started_at::DATE AS call_date,
       COUNT(*) AS total_calls,
       COUNT(*) FILTER (WHERE outcome = 'sale') AS sales,
       ROUND(100.0 * COUNT(*) FILTER (WHERE outcome = 'sale') / COUNT(*), 1) AS conversion_pct
FROM calls
GROUP BY call_date
ORDER BY call_date;

-- 6. Рейтинг менеджеров в команде с оконной функцией.
WITH manager_scores AS (
    SELECT m.team_name, m.full_name, ROUND(AVG(qr.total_score), 1) AS avg_score
    FROM managers m JOIN calls c ON c.manager_id = m.manager_id
    JOIN quality_reviews qr ON qr.call_id = c.call_id
    GROUP BY m.team_name, m.full_name
)
SELECT *, DENSE_RANK() OVER (PARTITION BY team_name ORDER BY avg_score DESC) AS team_rank
FROM manager_scores
ORDER BY team_name, team_rank;

-- 7. Последняя оценка каждого менеджера.
SELECT manager, reviewed_at, total_score
FROM (
    SELECT m.full_name AS manager, qr.reviewed_at, qr.total_score,
           ROW_NUMBER() OVER (PARTITION BY m.manager_id ORDER BY qr.reviewed_at DESC) AS rn
    FROM managers m JOIN calls c ON c.manager_id = m.manager_id
    JOIN quality_reviews qr ON qr.call_id = c.call_id
) ranked
WHERE rn = 1;

-- 8. Частота каждого типа нарушения.
SELECT vt.code, vt.title, vt.severity, COUNT(*) AS occurrences
FROM violation_types vt
LEFT JOIN review_violations rv ON rv.violation_type_id = vt.violation_type_id
GROUP BY vt.violation_type_id, vt.code, vt.title, vt.severity
ORDER BY occurrences DESC, vt.severity;

-- 9. Проверка качества данных: завершённые звонки без ссылки на запись.
SELECT call_id, started_at, outcome
FROM calls
WHERE outcome <> 'no_answer' AND recording_url IS NULL;

-- 10. Структура оценок: слабые блоки в проверках < 80 баллов.
SELECT c.call_id, m.full_name, qr.total_score,
       LEAST(qr.greeting_score / 20.0, qr.needs_score / 30.0,
             qr.solution_score / 30.0, qr.closing_score / 20.0) AS weakest_ratio
FROM quality_reviews qr
JOIN calls c ON c.call_id = qr.call_id
JOIN managers m ON m.manager_id = c.manager_id
WHERE qr.total_score < 80
ORDER BY qr.total_score;

-- 11. Накопительное число звонков по дням.
WITH daily AS (
    SELECT started_at::DATE AS call_date, COUNT(*) AS calls_count FROM calls GROUP BY 1
)
SELECT call_date, calls_count,
       SUM(calls_count) OVER (ORDER BY call_date) AS running_total
FROM daily
ORDER BY call_date;

-- 12. Менеджеры с минимум двумя проверками и средним баллом ниже 85.
SELECT m.full_name, COUNT(*) AS review_count, ROUND(AVG(qr.total_score), 1) AS avg_score
FROM managers m JOIN calls c ON c.manager_id = m.manager_id
JOIN quality_reviews qr ON qr.call_id = c.call_id
GROUP BY m.manager_id, m.full_name
HAVING COUNT(*) >= 2 AND AVG(qr.total_score) < 85;

-- 13. Матрица результатов звонков по командам.
SELECT m.team_name,
       COUNT(*) FILTER (WHERE c.outcome = 'sale') AS sales,
       COUNT(*) FILTER (WHERE c.outcome = 'follow_up') AS follow_ups,
       COUNT(*) FILTER (WHERE c.outcome = 'declined') AS declined
FROM managers m JOIN calls c ON c.manager_id = m.manager_id
GROUP BY m.team_name;

-- 14. Приоритетная очередь: неоценённые звонки сначала, затем низкие оценки и критические нарушения.
SELECT c.call_id, m.full_name, c.started_at, qr.total_score,
       COUNT(rv.violation_type_id) FILTER (WHERE vt.severity = 'critical') AS critical_violations
FROM calls c JOIN managers m ON m.manager_id = c.manager_id
LEFT JOIN quality_reviews qr ON qr.call_id = c.call_id
LEFT JOIN review_violations rv ON rv.review_id = qr.review_id
LEFT JOIN violation_types vt ON vt.violation_type_id = rv.violation_type_id
GROUP BY c.call_id, m.full_name, c.started_at, qr.total_score
ORDER BY (qr.review_id IS NULL) DESC, critical_violations DESC, qr.total_score ASC NULLS FIRST;
