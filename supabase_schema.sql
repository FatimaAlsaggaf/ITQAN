-- ==============================================================================
-- ITQAN PLATFORM - SUPABASE SCHEMA & INITIAL SEED DATA
-- منصة إتقان - ذكاء القوى العاملة
-- ==============================================================================
-- طريقة الاستخدام:
-- 1. افتح لوحة تحكم مشروعك في Supabase (https://supabase.com/dashboard)
-- 2. توجّه إلى القائمة الجانبية واختر "SQL Editor"
-- 3. انسخ هذا الكود بالكامل والصقه في المحرر ثم اضغط "RUN"
-- ==============================================================================

-- 1. تمكين الملحقات الضرورية
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. حذف الجداول القديمة إن وجدت للبدء من صفحة نظيفة
DROP TABLE IF EXISTS development_activities CASCADE;
DROP TABLE IF EXISTS development_plans CASCADE;
DROP TABLE IF EXISTS employee_evaluations CASCADE;
DROP TABLE IF EXISTS manager_evaluations CASCADE;
DROP TABLE IF EXISTS project_members CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS trainees CASCADE;
DROP TABLE IF EXISTS employee_skills CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS skills CASCADE;
DROP TABLE IF EXISTS cost_assumptions CASCADE;

-- ==============================================================================
-- 3. إنشاء الجداول (TABLES CREATION)
-- ==============================================================================

-- جدول المهارات والكفاءات
CREATE TABLE skills (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL,
    category TEXT NOT NULL,
    category_en TEXT NOT NULL,
    criticality TEXT NOT NULL CHECK (criticality IN ('critical', 'high', 'medium', 'low'))
);

-- جدول الموظفين
CREATE TABLE employees (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL,
    job_title TEXT NOT NULL,
    job_title_en TEXT NOT NULL,
    department TEXT NOT NULL,
    department_en TEXT NOT NULL,
    avatar_type TEXT DEFAULT 'man',
    availability TEXT NOT NULL CHECK (availability IN ('available', 'busy', 'partially_available', 'assigned')),
    workload NUMERIC NOT NULL DEFAULT 0,
    performance_score NUMERIC NOT NULL DEFAULT 4.0,
    experience_years NUMERIC NOT NULL DEFAULT 1,
    manager_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول مهارات الموظفين
CREATE TABLE employee_skills (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    skill_id TEXT NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    proficiency NUMERIC NOT NULL CHECK (proficiency BETWEEN 1 AND 5),
    verified BOOLEAN NOT NULL DEFAULT false,
    last_updated TEXT,
    UNIQUE(employee_id, skill_id)
);

-- جدول المشاريع
CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL,
    description TEXT,
    description_en TEXT,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    team_size NUMERIC NOT NULL DEFAULT 1,
    department TEXT NOT NULL,
    department_en TEXT NOT NULL,
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'high', 'medium', 'low')),
    status TEXT NOT NULL CHECK (status IN ('active', 'planning', 'completed', 'at_risk')),
    required_skill_ids TEXT[] DEFAULT '{}',
    preferred_skill_ids TEXT[] DEFAULT '{}',
    trainee_seat BOOLEAN DEFAULT false,
    manager_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول أعضاء فرق المشاريع
CREATE TABLE project_members (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    member_id TEXT NOT NULL,
    member_type TEXT NOT NULL CHECK (member_type IN ('employee', 'trainee')),
    role TEXT NOT NULL,
    role_en TEXT NOT NULL,
    match_score NUMERIC,
    selection_reason TEXT,
    selection_reason_en TEXT
);

-- جدول المهام التشغيلية
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    assigned_to TEXT NOT NULL,
    title TEXT NOT NULL,
    title_en TEXT NOT NULL,
    description TEXT,
    deadline TEXT NOT NULL,
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'high', 'medium', 'low')),
    status TEXT NOT NULL CHECK (status IN ('in_progress', 'completed', 'delayed', 'pending')),
    performance_rating NUMERIC,
    manager_feedback TEXT,
    completed_date TEXT,
    completion_note TEXT,
    is_trainee_task BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول المتدربين (برنامج التمكين والجاهزية)
CREATE TABLE trainees (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT NOT NULL,
    department TEXT NOT NULL,
    department_en TEXT NOT NULL,
    target_skill_id TEXT NOT NULL REFERENCES skills(id),
    current_skill_ids TEXT[] DEFAULT '{}',
    learning_goals TEXT,
    learning_goals_en TEXT,
    mentor_id TEXT NOT NULL,
    start_date TEXT NOT NULL,
    expected_completion TEXT NOT NULL,
    progress NUMERIC NOT NULL DEFAULT 0,
    availability TEXT NOT NULL CHECK (availability IN ('available', 'assigned', 'graduated')),
    status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'paused', 'ready_for_promotion')),
    avatar_type TEXT DEFAULT 'man',
    current_project_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول خطط التطوير الفردية
CREATE TABLE development_plans (
    id TEXT PRIMARY KEY,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    target_skill_id TEXT NOT NULL REFERENCES skills(id),
    current_level NUMERIC NOT NULL DEFAULT 1,
    target_level NUMERIC NOT NULL DEFAULT 4,
    progress NUMERIC NOT NULL DEFAULT 0,
    development_method TEXT NOT NULL,
    development_goal TEXT NOT NULL,
    development_goal_en TEXT NOT NULL,
    reason TEXT NOT NULL,
    reason_en TEXT NOT NULL,
    mentor_id TEXT,
    estimated_cost NUMERIC NOT NULL DEFAULT 0,
    duration_months NUMERIC NOT NULL DEFAULT 1,
    remaining_weeks TEXT,
    start_date TEXT NOT NULL,
    review_date TEXT,
    status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'paused')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول أنشطة خطط التطوير
CREATE TABLE development_activities (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    plan_id TEXT NOT NULL REFERENCES development_plans(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    title_en TEXT NOT NULL,
    type TEXT NOT NULL,
    provider TEXT NOT NULL,
    provider_en TEXT NOT NULL,
    duration_label TEXT,
    duration_label_en TEXT,
    completed_hours NUMERIC DEFAULT 0,
    total_hours NUMERIC DEFAULT 0,
    progress NUMERIC NOT NULL DEFAULT 0,
    status TEXT NOT NULL CHECK (status IN ('not_started', 'in_progress', 'completed')),
    target_completion_date TEXT,
    cost NUMERIC DEFAULT 0
);

-- جدول تقييمات الموظفين
CREATE TABLE employee_evaluations (
    id TEXT PRIMARY KEY,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    employee_name TEXT NOT NULL,
    employee_name_en TEXT NOT NULL,
    manager_id TEXT NOT NULL,
    date TEXT NOT NULL,
    deliverables_quality NUMERIC NOT NULL CHECK (deliverables_quality BETWEEN 1 AND 5),
    deadline_adherence NUMERIC NOT NULL CHECK (deadline_adherence BETWEEN 1 AND 5),
    team_collaboration NUMERIC NOT NULL CHECK (team_collaboration BETWEEN 1 AND 5),
    initiative_skill_growth NUMERIC NOT NULL CHECK (initiative_skill_growth BETWEEN 1 AND 5),
    overall_rating NUMERIC NOT NULL,
    comments TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول تقييمات المدراء
CREATE TABLE manager_evaluations (
    id TEXT PRIMARY KEY,
    manager_id TEXT NOT NULL,
    manager_name TEXT NOT NULL,
    manager_name_en TEXT NOT NULL,
    manager_job_title TEXT NOT NULL,
    manager_job_title_en TEXT NOT NULL,
    evaluator_id TEXT NOT NULL,
    date TEXT NOT NULL,
    project_adherence NUMERIC NOT NULL CHECK (project_adherence BETWEEN 1 AND 5),
    team_workload_management NUMERIC NOT NULL CHECK (team_workload_management BETWEEN 1 AND 5),
    employee_development NUMERIC NOT NULL CHECK (employee_development BETWEEN 1 AND 5),
    skill_risk_mitigation NUMERIC NOT NULL CHECK (skill_risk_mitigation BETWEEN 1 AND 5),
    overall_rating NUMERIC NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول افتراضات التكاليف المعتمدة
CREATE TABLE cost_assumptions (
    id TEXT PRIMARY KEY DEFAULT 'default',
    certification_cost NUMERIC NOT NULL DEFAULT 3500,
    training_course_cost NUMERIC NOT NULL DEFAULT 4500,
    bootcamp_cost NUMERIC NOT NULL DEFAULT 12000,
    mentorship_cost NUMERIC NOT NULL DEFAULT 2000,
    practical_project_cost NUMERIC NOT NULL DEFAULT 5000,
    external_hiring_salary NUMERIC NOT NULL DEFAULT 24000,
    recruitment_onboarding_cost NUMERIC NOT NULL DEFAULT 18000,
    average_hiring_duration_months NUMERIC NOT NULL DEFAULT 3
);

-- ==============================================================================
-- 4. إعداد الصلاحيات والأمان (ROW LEVEL SECURITY & POLICIES)
-- ==============================================================================
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainees ENABLE ROW LEVEL SECURITY;
ALTER TABLE development_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE development_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE manager_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE cost_assumptions ENABLE ROW LEVEL SECURITY;

-- سياسات الوصول المباشر (تسمح لـ anon و authenticated بالقراءة والكتابة بسلاسة)
CREATE POLICY "Public Read Access skills" ON skills FOR SELECT USING (true);
CREATE POLICY "Public Write Access skills" ON skills FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access employees" ON employees FOR SELECT USING (true);
CREATE POLICY "Public Write Access employees" ON employees FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access employee_skills" ON employee_skills FOR SELECT USING (true);
CREATE POLICY "Public Write Access employee_skills" ON employee_skills FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access projects" ON projects FOR SELECT USING (true);
CREATE POLICY "Public Write Access projects" ON projects FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access project_members" ON project_members FOR SELECT USING (true);
CREATE POLICY "Public Write Access project_members" ON project_members FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access tasks" ON tasks FOR SELECT USING (true);
CREATE POLICY "Public Write Access tasks" ON tasks FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access trainees" ON trainees FOR SELECT USING (true);
CREATE POLICY "Public Write Access trainees" ON trainees FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access development_plans" ON development_plans FOR SELECT USING (true);
CREATE POLICY "Public Write Access development_plans" ON development_plans FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access development_activities" ON development_activities FOR SELECT USING (true);
CREATE POLICY "Public Write Access development_activities" ON development_activities FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access employee_evaluations" ON employee_evaluations FOR SELECT USING (true);
CREATE POLICY "Public Write Access employee_evaluations" ON employee_evaluations FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access manager_evaluations" ON manager_evaluations FOR SELECT USING (true);
CREATE POLICY "Public Write Access manager_evaluations" ON manager_evaluations FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Public Read Access cost_assumptions" ON cost_assumptions FOR SELECT USING (true);
CREATE POLICY "Public Write Access cost_assumptions" ON cost_assumptions FOR ALL USING (true) WITH CHECK (true);

-- ==============================================================================
-- 5. إدراج البيانات الأولية (SEED DATA)
-- ==============================================================================

-- 5.1 المهارات (Skills)
INSERT INTO skills (id, name, name_en, category, category_en, criticality) VALUES
('skill-cloud-security', 'أمن الحوسبة السحابية', 'Cloud Security', 'الأمن السيبراني', 'Cybersecurity', 'critical'),
('skill-data-eng', 'هندسة البيانات', 'Data Engineering', 'البيانات والذكاء الاصطناعي', 'Data & AI', 'high'),
('skill-ml', 'تعلم الآلة والذكاء الاصطناعي', 'Machine Learning & AI', 'البيانات والذكاء الاصطناعي', 'Data & AI', 'high'),
('skill-devops', 'إدارة الحاويات وعمليات التطوير', 'Kubernetes & DevOps', 'البنية السحابية', 'Cloud & Infrastructure', 'high'),
('skill-react', 'تطوير واجهات الويب المتقدمة', 'React & Frontend Engineering', 'تطوير البرمجيات', 'Software Engineering', 'medium'),
('skill-ui-ux', 'تصميم تجربة وواجهة المستخدم', 'UI/UX Design', 'التصميم والابتكار', 'Design & UX', 'medium'),
('skill-sys-arch', 'بنية النظم الموزعة', 'Distributed System Architecture', 'تطوير البرمجيات', 'Software Engineering', 'critical'),
('skill-data-analytics', 'تحليل البيانات ونمذجة الأعمال', 'Data Analytics & Modeling', 'البيانات والذكاء الاصطناعي', 'Data & AI', 'high'),
('skill-qa', 'ضمان الجودة وأتمتة الاختبارات', 'QA & Automated Testing', 'تطوير البرمجيات', 'Software Engineering', 'medium'),
('skill-product-mgmt', 'إدارة المنتجات الرقمية', 'Digital Product Management', 'الإدارة والاستراتيجية', 'Strategy & Mgmt', 'high'),
('skill-nlp', 'معالجة اللغات الطبيعية ونماذج LLM', 'Natural Language Processing & LLMs', 'البيانات والذكاء الاصطناعي', 'Data & AI', 'high'),
('skill-incident-response', 'الاستجابة للحوادث السيبرانية', 'Incident Response & Threat Hunting', 'الأمن السيبراني', 'Cybersecurity', 'critical'),
('skill-backend-node', 'تطوير النظم الخلفية والواجهات البرمجية', 'Backend Systems & API Architecture', 'تطوير البرمجيات', 'Software Engineering', 'high'),
('skill-database-admin', 'إدارة وتوسيع قواعد البيانات المتقدمة', 'Database Administration & Scalability', 'البنية السحابية', 'Cloud & Infrastructure', 'critical')
ON CONFLICT (id) DO NOTHING;

-- 5.2 الموظفون (Employees)
INSERT INTO employees (id, user_id, name, name_en, job_title, job_title_en, department, department_en, avatar_type, availability, workload, performance_score, experience_years, manager_id) VALUES
('emp-ahmed', 'user-emp-1', 'أحمد الغامدي', 'Ahmed Al-Ghamdi', 'أخصائي تحليل بيانات أول', 'Senior Data Analyst', 'البيانات والذكاء الاصطناعي', 'Data & AI', 'man', 'partially_available', 65, 4.6, 6, 'user-mgr-1'),
('emp-sara', 'user-emp-2', 'سارة العتيبي', 'Sara Al-Otaibi', 'كبير مهندسي الذكاء الاصطناعي', 'Principal AI Engineer', 'البيانات والذكاء الاصطناعي', 'Data & AI', 'woman', 'available', 50, 4.8, 8, 'user-mgr-1'),
('emp-khalid', 'user-emp-3', 'خالد الدوسري', 'Khalid Al-Dossari', 'مهندس أمن سيبراني وسحابي', 'Cloud Security Architect', 'الأمن السيبراني', 'Cybersecurity', 'man', 'busy', 95, 4.9, 9, 'user-mgr-1'),
('emp-noura', 'user-emp-4', 'نورة الشهري', 'Noura Al-Shehri', 'مهندسة واجهات وتجربة مستخدم', 'Senior Frontend Engineer', 'تطوير البرمجيات', 'Software Engineering', 'woman', 'available', 40, 4.5, 5, 'user-mgr-1'),
('emp-fهد', 'user-emp-5', 'فهد القحطاني', 'Fahad Al-Qahtani', 'مهندس بنية سحابية وديف أوبس', 'Lead DevOps Engineer', 'البنية السحابية', 'Cloud & Infrastructure', 'man', 'busy', 90, 4.7, 7, 'user-mgr-1'),
('emp-reem', 'user-emp-6', 'ريم المطيري', 'Reem Al-Mutairi', 'مديرة منتجات رقمية', 'Lead Digital Product Manager', 'الإدارة والاستراتيجية', 'Strategy & Mgmt', 'woman', 'available', 45, 4.4, 6, 'user-mgr-1'),
('emp-omar', 'user-emp-7', 'عمر الحربي', 'Omar Al-Harbi', 'مهندس نظم موزعة وخلفية', 'Principal Backend Engineer', 'تطوير البرمجيات', 'Software Engineering', 'man', 'partially_available', 70, 4.6, 8, 'user-mgr-1'),
('emp-maha', 'user-emp-8', 'مها الزهراني', 'Maha Al-Zahrani', 'أخصائية ضمان جودة وأتمتة', 'QA Automation Specialist', 'تطوير البرمجيات', 'Software Engineering', 'woman', 'available', 35, 4.3, 4, 'user-mgr-1')
ON CONFLICT (id) DO NOTHING;

-- 5.3 مهارات الموظفين (Employee Skills)
INSERT INTO employee_skills (employee_id, skill_id, proficiency, verified, last_updated) VALUES
('emp-ahmed', 'skill-data-analytics', 5, true, '2026-08-15'),
('emp-ahmed', 'skill-ml', 3, true, '2026-07-10'),
('emp-ahmed', 'skill-qa', 4, false, '2026-06-20'),
('emp-sara', 'skill-ml', 5, true, '2026-09-01'),
('emp-sara', 'skill-data-eng', 4, true, '2026-08-10'),
('emp-sara', 'skill-data-analytics', 5, true, '2026-05-12'),
('emp-sara', 'skill-nlp', 4, true, '2026-08-25'),
('emp-khalid', 'skill-cloud-security', 5, true, '2026-09-12'),
('emp-khalid', 'skill-devops', 4, true, '2026-08-01'),
('emp-khalid', 'skill-incident-response', 5, true, '2026-09-15'),
('emp-noura', 'skill-react', 5, true, '2026-08-20'),
('emp-noura', 'skill-ui-ux', 4, true, '2026-07-15'),
('emp-noura', 'skill-qa', 3, false, '2026-05-10'),
('emp-fهد', 'skill-devops', 5, true, '2026-09-05'),
('emp-fهد', 'skill-cloud-security', 3, true, '2026-06-30'),
('emp-fهد', 'skill-database-admin', 4, true, '2026-07-22'),
('emp-reem', 'skill-product-mgmt', 5, true, '2026-08-18'),
('emp-reem', 'skill-data-analytics', 3, false, '2026-06-14'),
('emp-reem', 'skill-ui-ux', 4, true, '2026-07-02'),
('emp-omar', 'skill-sys-arch', 5, true, '2026-09-10'),
('emp-omar', 'skill-backend-node', 5, true, '2026-08-14'),
('emp-omar', 'skill-database-admin', 4, true, '2026-07-18'),
('emp-maha', 'skill-qa', 5, true, '2026-08-28'),
('emp-maha', 'skill-react', 3, false, '2026-06-15')
ON CONFLICT (employee_id, skill_id) DO NOTHING;

-- 5.4 المشاريع (Projects)
INSERT INTO projects (id, name, name_en, description, description_en, start_date, end_date, team_size, department, department_en, priority, status, required_skill_ids, preferred_skill_ids, trainee_seat, manager_id) VALUES
('proj-bi-portal', 'بوابة ذكاء الأعمال الموحدة', 'Unified BI & Analytics Platform', 'منظومة مركزية لاستخراج وتحليل مؤشرات الأداء الحيوية لكافة قطاعات المؤسسة.', 'Centralized analytics engine for cross-department KPI tracking.', '2026-08-01', '2026-11-30', 3, 'البيانات والذكاء الاصطناعي', 'Data & AI', 'urgent', 'active', ARRAY['skill-data-analytics', 'skill-ml', 'skill-react'], ARRAY['skill-data-eng'], true, 'user-mgr-1'),
('proj-cloud-mig', 'ترحيل البنية التحتية السحابية', 'Hybrid Cloud Security Migration', 'تأمين ونقل التطبيقات الجوهرية إلى بنية سحابية هجينة متطابقة مع ضوابط الأمن الوطني.', 'Migrating legacy services into secure sovereign hybrid cloud architecture.', '2026-07-15', '2026-12-15', 4, 'البنية السحابية', 'Cloud & Infrastructure', 'urgent', 'at_risk', ARRAY['skill-cloud-security', 'skill-devops', 'skill-sys-arch'], ARRAY['skill-database-admin'], false, 'user-mgr-1'),
('proj-crm-revamp', 'تطوير منظومة تجربة المستفيد', 'Beneficiary Experience Portal', 'إعادة هندسة رحلة المستفيد عبر واجهات عصرية ومؤتمتة بالذكاء الاصطناعي.', 'Re-architecting customer interactions with conversational AI & modern UI.', '2026-09-01', '2027-01-30', 3, 'تطوير البرمجيات', 'Software Engineering', 'high', 'planning', ARRAY['skill-react', 'skill-ui-ux', 'skill-product-mgmt'], ARRAY['skill-qa'], true, 'user-mgr-1'),
('proj-cyber-shield', 'برنامج الدرع السيبراني الوقائي', 'Proactive Cyber Defense Initiative', 'بناء مركز عمليات متقدم لرصد وتحليل التهديدات واختبار الاختراق الآلي.', 'Advanced threat detection and continuous security compliance dashboard.', '2026-06-01', '2026-10-30', 2, 'الأمن السيبراني', 'Cybersecurity', 'high', 'active', ARRAY['skill-cloud-security', 'skill-incident-response'], ARRAY['skill-devops'], false, 'user-mgr-1')
ON CONFLICT (id) DO NOTHING;

-- 5.5 أعضاء فرق المشاريع (Project Members)
INSERT INTO project_members (project_id, member_id, member_type, role, role_en, match_score, selection_reason, selection_reason_en) VALUES
('proj-bi-portal', 'emp-ahmed', 'employee', 'كبير محللي البيانات', 'Lead Data Analyst', 96, 'تطابق تام مع مهارة تحليل البيانات ونمذجة الأعمال', '100% verified match on Data Analytics'),
('proj-bi-portal', 'emp-sara', 'employee', 'مهندسة ذكاء اصطناعي', 'AI Lead', 92, 'خبرة عميقة في تعلم الآلة وبناء نماذج التنبؤ', 'Deep expertise in machine learning and predictive models'),
('proj-bi-portal', 'tr-1', 'trainee', 'متدرب تمكين - تحليل بيانات', 'Associate Trainee', 88, 'مقعد تدريب تطبيقي لرفع الجاهزية', 'Assigned enablement seat for hands-on skill growth'),
('proj-cloud-mig', 'emp-khalid', 'employee', 'معماري أمن سحابي', 'Cloud Security Architect', 98, 'خبير المهارة النادرة والحرجة في أمن السحابة', 'Critical skill holder in Cloud Security'),
('proj-cloud-mig', 'emp-fهد', 'employee', 'مهندس ديف أوبس', 'Lead DevOps', 94, 'إتقان متكامل للحاويات وأتمتة النشر السحابي', 'Top proficiency in Kubernetes & CI/CD pipelines'),
('proj-cloud-mig', 'emp-omar', 'employee', 'مهندس نظم خلفية', 'Backend Architect', 91, 'تأمين تدفق البيانات وبنية النظم الموزعة', 'Architectural expertise in distributed transactions'),
('proj-crm-revamp', 'emp-noura', 'employee', 'مهندسة واجهات أمامية', 'Lead Frontend Engineer', 95, 'إتقان تام لمكتبة React وتصميم الواجهات', 'Mastery in React ecosystem and responsive design'),
('proj-crm-revamp', 'emp-reem', 'employee', 'مديرة المنتج', 'Product Lead', 90, 'مواءمة مستهدفات الأعمال مع تجربة العميل', 'Strong alignment with business and UI requirements'),
('proj-cyber-shield', 'emp-khalid', 'employee', 'قائد الفريق الأمني', 'Security Operations Lead', 99, 'خبير معتمد في الاستجابة للحوادث السيبرانية', 'Certified expert in incident response & hunting')
ON CONFLICT DO NOTHING;

-- 5.6 المهام التشغيلية (Tasks)
INSERT INTO tasks (id, project_id, assigned_to, title, title_en, description, deadline, priority, status, performance_rating, manager_feedback, completed_date, completion_note, is_trainee_task) VALUES
('task-1', 'proj-bi-portal', 'emp-ahmed', 'بناء لوحة المؤشرات الاستراتيجية التفاعلية', 'Build Interactive Strategic KPI Dashboard', 'تصميم وتطوير مستودع البيانات التفاعلي وعرض المؤشرات اللحظية.', '2026-10-15', 'urgent', 'in_progress', NULL, NULL, NULL, NULL, false),
('task-2', 'proj-bi-portal', 'emp-sara', 'تدريب واختبار نموذج التنبؤ بتدفق الإيرادات', 'Train & Evaluate Predictive Revenue Model', 'بناء وتدريب نموذج الذكاء الاصطناعي على بيانات السنوات الخمس الماضية.', '2026-10-20', 'high', 'in_progress', NULL, NULL, NULL, NULL, false),
('task-3', 'proj-bi-portal', 'tr-1', 'توثيق قواميس البيانات وتجهيز تقارير المراجعة', 'Data Dictionary Documentation & Audit Reports', 'مراجعة اتساق الحقول والجداول وإعداد مسودات التقارير الأسبوعية.', '2026-10-25', 'medium', 'in_progress', NULL, NULL, NULL, NULL, true),
('task-4', 'proj-cloud-mig', 'emp-khalid', 'مراجعة وتدقيق معايير التشفير والامتثال السحابي', 'Review Encryption Standards & Cloud Compliance', 'فحص شهادات الأمان وسياسات عزل الشبكات والمفاتيح المشفرة.', '2026-10-10', 'urgent', 'completed', 5.0, 'إنجاز استثنائي ودقة عالية في التقييم الأمني', '2026-10-02', 'تم الانتهاء والتحقق بنجاح من كافة متطلبات الأمن الوطني.', false),
('task-5', 'proj-cloud-mig', 'emp-fهد', 'أتمتة خطوط النشر وتجهيز حاويات Kubernetes', 'Automate CI/CD Pipelines & Provision K8s', 'بناء خطوط النشر التلقائية وتأمين مستودعات الحاويات.', '2026-10-18', 'high', 'in_progress', NULL, NULL, NULL, NULL, false),
('task-6', 'proj-cloud-mig', 'emp-omar', 'إعادة هيكلة طبقة التخزين وقواعد البيانات الموزعة', 'Refactor Distributed Database Storage Layer', 'تحسين الاستعلامات والتحقق من التكرار الجغرافي للبيانات.', '2026-10-28', 'high', 'in_progress', NULL, NULL, NULL, NULL, false),
('task-7', 'proj-crm-revamp', 'emp-noura', 'بناء منظومة التصميم ومكتبة المكونات الموحدة', 'Design System Implementation & Component Library', 'إنشاء مكتبة المكونات الداعمة للغتين والوضع الليلي.', '2026-10-30', 'medium', 'in_progress', NULL, NULL, NULL, NULL, false),
('task-8', 'proj-crm-revamp', 'emp-reem', 'تحديد مسارات رحلة العميل ومؤشرات الرضا', 'Define User Journeys & Customer Satisfaction Metrics', 'عقد ورش عمل مع المستفيدين وتحديد الأولويات الوظيفية.', '2026-10-12', 'high', 'completed', 4.5, 'تنسيق ممتاز مع الإدارات التشغيلية', '2026-10-04', 'تم اعتماد نطاق العمل والمستهدفات رسمياً.', false),
('task-9', 'proj-cyber-shield', 'emp-khalid', 'إجراء اختبارات الاختراق الشاملة للبوابات الخارجية', 'Conduct Penetration Testing on Public Gateways', 'محاكاة الهجمات واكتشاف الثغرات وتوثيق خطة المعالجة الفورية.', '2026-10-08', 'urgent', 'completed', 4.8, 'جهد احترافي وقائي حاسم', '2026-10-05', 'تم إغلاق كافة الملاحظات وعزل المسارات غير الآمنة.', false),
('task-10', 'proj-bi-portal', 'emp-ahmed', 'تجهيز واجهات ربط API مع الأنظمة المالية المركزية', 'Integrate Financial Core APIs with Data Warehouse', 'ربط الجداول المحاسبية واستخراج التدفقات اليومية.', '2026-10-14', 'urgent', 'in_progress', NULL, NULL, NULL, NULL, false)
ON CONFLICT (id) DO NOTHING;

-- 5.7 المتدربون (Trainees)
INSERT INTO trainees (id, name, name_en, department, department_en, target_skill_id, current_skill_ids, learning_goals, learning_goals_en, mentor_id, start_date, expected_completion, progress, availability, status, avatar_type, current_project_id) VALUES
('tr-1', 'سعود الشمري', 'Saud Al-Shammari', 'البيانات والذكاء الاصطناعي', 'Data & AI', 'skill-data-eng', ARRAY['skill-data-analytics'], 'بناء خطوط معالجة البيانات ETL وتحسين استعلامات SQL', 'Master ETL pipelines and SQL performance optimization', 'emp-sara', '2026-06-01', '2026-11-01', 82, 'assigned', 'ready_for_promotion', 'man', 'proj-bi-portal'),
('tr-2', 'نادية السالم', 'Nadia Al-Salem', 'الأمن السيبراني', 'Cybersecurity', 'skill-cloud-security', ARRAY['skill-devops'], 'اكتساب كفاءة تدقيق أمن السحابة ومعالجة الثغرات السيبرانية', 'Acquire cloud security auditing and vulnerability mitigation skills', 'emp-khalid', '2026-07-01', '2026-12-01', 65, 'available', 'active', 'woman', NULL),
('tr-3', 'فيصل الدوسري', 'Faisal Al-Dossari', 'تطوير البرمجيات', 'Software Engineering', 'skill-react', ARRAY['skill-ui-ux'], 'تطوير الواجهات التفاعلية المتقدمة وإتقان إدارة الحالة', 'Building dynamic responsive interfaces and state management', 'emp-noura', '2026-08-01', '2027-01-01', 40, 'available', 'active', 'man', NULL),
('tr-4', 'دلال القحطاني', 'Dalal Al-Qahtani', 'البنية السحابية', 'Cloud & Infrastructure', 'skill-devops', ARRAY['skill-sys-arch'], 'أتمتة النشر وإدارة الحاويات السحابية ومراقبة الأداء', 'Automating deployments, container orchestration and system monitoring', 'emp-fهد', '2026-09-01', '2027-02-01', 25, 'available', 'active', 'woman', NULL)
ON CONFLICT (id) DO NOTHING;

-- 5.8 خطط التطوير الفردية (Development Plans)
INSERT INTO development_plans (id, employee_id, target_skill_id, current_level, target_level, progress, development_method, development_goal, development_goal_en, reason, reason_en, mentor_id, estimated_cost, duration_months, remaining_weeks, start_date, review_date, status, notes) VALUES
('plan-ahmed-1', 'emp-ahmed', 'skill-ml', 3, 4, 60, 'برنامج تدريبي تطبيقي مكثف ومشاريع عملية', 'رفع الكفاءة في بناء نماذج تعلم الآلة المتقدمة واستخراج التنبؤات', 'Elevate proficiency in building advanced machine learning models and predictive analytics', 'تمكين الموظف من قيادة النمذجة المتقدمة في مشاريع ذكاء الأعمال', 'Equip employee to lead predictive modeling in business intelligence initiatives', 'emp-sara', 7500, 3, '4 أسابيع', '2026-08-01', '2026-11-01', 'active', 'الموظف يظهر تقدماً سريعاً في التطبيق العملي والمشاريع الحية.'),
('plan-noura-1', 'emp-noura', 'skill-qa', 3, 4, 35, 'معسكر تدريبي وشهادة مهنية في أتمتة الاختبارات', 'احتراف أتمتة اختبارات الواجهات وضمان الجودة المستمر', 'Master end-to-end frontend testing automation and QA workflows', 'دعم استقلالية فرق التطوير وتقليص الأخطاء قبل إطلاق الإصدارات', 'Enhance engineering squad self-sufficiency and reduce production bugs', 'emp-maha', 5500, 2, '6 أسابيع', '2026-09-01', '2026-11-15', 'active', 'تم إنجاز الجانب النظري وبدء التدريب على كتابة سيناريوهات الأتمتة.')
ON CONFLICT (id) DO NOTHING;

-- 5.9 أنشطة خطط التطوير (Development Activities)
INSERT INTO development_activities (plan_id, title, title_en, type, provider, provider_en, duration_label, duration_label_en, completed_hours, total_hours, progress, status, target_completion_date, cost) VALUES
('plan-ahmed-1', 'دورة متقدمة في تعلم الآلة والشبكات العصبية', 'Advanced Machine Learning & Neural Networks', 'course', 'معهد الذكاء الاصطناعي التخصصي', 'Specialized AI Institute', '40 ساعة', '40 hours', 40, 40, 100, 'completed', '2026-08-30', 3500),
('plan-ahmed-1', 'مشروع تطبيقي: التنبؤ بمؤشرات أداء المؤسسة', 'Capstone Project: Institutional KPI Forecasting', 'project', 'إتقان - العمل الداخلي التطبيقي', 'Itqan Internal Sandbox', '30 ساعة', '30 hours', 15, 30, 50, 'in_progress', '2026-10-15', 2000),
('plan-ahmed-1', 'جلسات توجيه مهني أسبوعية مع كبير المهندسين', 'Weekly Mentorship with Principal AI Lead', 'mentorship', 'سارة العتيبي (مرشد داخلي)', 'Sara Al-Otaibi', '10 ساعات', '10 hours', 5, 10, 50, 'in_progress', '2026-10-30', 2000),
('plan-noura-1', 'شهادة أتمتة الاختبارات عبر Cypress و Playwright', 'Test Automation with Cypress & Playwright Certification', 'certification', 'أكاديمية ضمان الجودة العالمية', 'Global QA Academy', '35 ساعة', '35 hours', 20, 35, 57, 'in_progress', '2026-10-20', 3500),
('plan-noura-1', 'تطبيق خط اختبارات مؤتمت لبوابة المستفيد', 'Implement Automated Test Suite for Beneficiary Portal', 'project', 'مشروع تطبيقي بإشراف خبير الجودة', 'Applied Project under QA Specialist', '20 ساعة', '20 hours', 0, 20, 0, 'not_started', '2026-11-10', 2000)
ON CONFLICT DO NOTHING;

-- 5.10 تقييمات الموظفين (Employee Evaluations)
INSERT INTO employee_evaluations (id, employee_id, employee_name, employee_name_en, manager_id, date, deliverables_quality, deadline_adherence, team_collaboration, initiative_skill_growth, overall_rating, comments) VALUES
('eval-emp-1', 'emp-ahmed', 'أحمد الغامدي', 'Ahmed Al-Ghamdi', 'user-mgr-1', '2026-09-15', 5, 4, 5, 4, 4.6, 'أداء متميز والتزام تام بجودة المخرجات، ويظهر رغبة مستمرة في التطور والتعلم.'),
('eval-emp-2', 'emp-sara', 'سارة العتيبي', 'Sara Al-Otaibi', 'user-mgr-1', '2026-09-10', 5, 5, 5, 5, 5.0, 'قيادة استثنائية للفريق التقني وحلول مبتكرة رفعت من كفاءة نماذج الذكاء الاصطناعي بشكل ملحوظ.'),
('eval-emp-3', 'emp-khalid', 'خالد الدوسري', 'Khalid Al-Dossari', 'user-mgr-1', '2026-09-20', 5, 5, 4, 5, 4.8, 'يقظة أمنية عالية وسرعة استجابة جنّبت المنظومة مخاطر كبرى خلال عمليات الترحيل السحابي.'),
('eval-emp-4', 'emp-noura', 'نورة الشهري', 'Noura Al-Shehri', 'user-mgr-1', '2026-09-05', 4, 5, 5, 4, 4.5, 'تصميمات إبداعية وسرعة في إنجاز الواجهات التفاعلية مع دعم كامل لمعايير الوصول الشامل.'),
('eval-emp-5', 'emp-fهد', 'فهد القحطاني', 'Fahad Al-Qahtani', 'user-mgr-1', '2026-09-18', 5, 4, 4, 5, 4.6, 'إدارة متمكنة للبنية السحابية وأتمتة فعالة ساهمت في تقليص فترات التوقف.')
ON CONFLICT (id) DO NOTHING;

-- 5.11 تقييمات المدراء (Manager Evaluations)
INSERT INTO manager_evaluations (id, manager_id, manager_name, manager_name_en, manager_job_title, manager_job_title_en, evaluator_id, date, project_adherence, team_workload_management, employee_development, skill_risk_mitigation, overall_rating, notes) VALUES
('eval-mgr-1', 'user-mgr-1', 'طارق المنصور', 'Tariq Al-Mansour', 'مدير قطاع الحلول الرقمية', 'Digital Solutions Manager', 'user-snr-1', '2026-09-25', 5, 4, 5, 5, 4.8, 'قيادة استراتيجية واعية حققت التوازن بين إنجاز المشاريع وتطوير الكفاءات الوطنية وتقليص المخاطر السيبرانية.'),
('eval-mgr-2', 'user-mgr-2', 'منى الرويلي', 'Mona Al-Ruwaili', 'مديرة إدارة البيانات والذكاء الاصطناعي', 'Data & AI Director', 'user-snr-1', '2026-09-22', 4, 5, 4, 4, 4.4, 'إدارة متوازنة لعبء العمل وتوزيع مثالي للمهام التخصصية بين المهندسين.')
ON CONFLICT (id) DO NOTHING;

-- 5.12 افتراضات التكاليف (Cost Assumptions)
INSERT INTO cost_assumptions (id, certification_cost, training_course_cost, bootcamp_cost, mentorship_cost, practical_project_cost, external_hiring_salary, recruitment_onboarding_cost, average_hiring_duration_months) VALUES
('default', 3500, 4500, 12000, 2000, 5000, 24000, 18000, 3)
ON CONFLICT (id) DO UPDATE SET
    certification_cost = EXCLUDED.certification_cost,
    training_course_cost = EXCLUDED.training_course_cost,
    bootcamp_cost = EXCLUDED.bootcamp_cost,
    mentorship_cost = EXCLUDED.mentorship_cost,
    practical_project_cost = EXCLUDED.practical_project_cost,
    external_hiring_salary = EXCLUDED.external_hiring_salary,
    recruitment_onboarding_cost = EXCLUDED.recruitment_onboarding_cost,
    average_hiring_duration_months = EXCLUDED.average_hiring_duration_months;

-- ==============================================================================
-- نهاية الملف - اكتمل بناء الهيكل وإدخال البيانات بنجاح!
-- ==============================================================================
