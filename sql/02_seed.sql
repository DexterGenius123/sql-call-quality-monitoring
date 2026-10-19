INSERT INTO managers (full_name, team_name, hired_at) VALUES
('Алия Нуржанова', 'Продажи A', '2024-03-11'),
('Данияр Ахметов', 'Продажи A', '2023-09-01'),
('Мария Ким', 'Продажи B', '2025-01-20'),
('Тимур Садыков', 'Продажи B', '2024-07-15');

INSERT INTO violation_types (code, title, severity) VALUES
('NO_GREETING', 'Не представился в начале разговора', 'medium'),
('NO_CONSENT', 'Не получил согласие на обработку данных', 'critical'),
('WRONG_PROMISE', 'Некорректное обещание клиенту', 'critical'),
('NO_FOLLOW_UP', 'Не зафиксировал следующий шаг', 'low');

INSERT INTO calls (manager_id, started_at, duration_sec, direction, outcome, recording_url) VALUES
(1, '2026-10-01 04:10+00', 355, 'outbound', 'sale', 'https://records.example/1'),
(1, '2026-10-02 05:30+00', 120, 'outbound', 'follow_up', 'https://records.example/2'),
(2, '2026-10-01 06:05+00', 480, 'inbound', 'sale', 'https://records.example/3'),
(2, '2026-10-03 03:20+00', 75, 'outbound', 'declined', 'https://records.example/4'),
(3, '2026-10-02 08:15+00', 520, 'inbound', 'follow_up', 'https://records.example/5'),
(3, '2026-10-04 04:40+00', 180, 'outbound', 'no_answer', NULL),
(4, '2026-10-03 07:10+00', 330, 'inbound', 'sale', 'https://records.example/7'),
(4, '2026-10-05 05:55+00', 260, 'outbound', 'follow_up', 'https://records.example/8'),
(1, '2026-10-06 04:20+00', 410, 'outbound', 'sale', 'https://records.example/9'),
(2, '2026-10-06 06:45+00', 290, 'inbound', 'declined', 'https://records.example/10');

INSERT INTO quality_reviews (call_id, reviewer_name, reviewed_at, greeting_score, needs_score, solution_score, closing_score, comment) VALUES
(1, 'Айгерим Ж.', '2026-10-01 08:00+00', 20, 27, 28, 20, 'Сценарий соблюдён'),
(2, 'Айгерим Ж.', '2026-10-02 10:00+00', 15, 20, 23, 15, 'Нужно лучше фиксировать следующий шаг'),
(3, 'Николай П.', '2026-10-01 09:00+00', 20, 28, 30, 18, 'Хорошая работа с возражениями'),
(4, 'Николай П.', '2026-10-04 08:00+00', 10, 17, 15, 10, 'Есть критическое нарушение'),
(5, 'Айгерим Ж.', '2026-10-02 12:00+00', 20, 29, 29, 19, 'Сценарий соблюдён'),
(7, 'Николай П.', '2026-10-03 11:00+00', 20, 25, 26, 18, 'Есть замечание по следующему шагу'),
(9, 'Айгерим Ж.', '2026-10-07 08:00+00', 20, 30, 30, 20, 'Отличный звонок');

INSERT INTO review_violations (review_id, violation_type_id) VALUES
(2, 4), (4, 2), (4, 3), (6, 4);
