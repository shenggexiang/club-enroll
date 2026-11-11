-- ============================================
-- 校园社团招新系统 · 数据库初始化脚本
-- 适用：MySQL 8.0+
-- 字符集：utf8mb4
-- 说明：脚本会删除并重建 club_enroll 库，仅用于本地开发环境
-- ============================================

DROP DATABASE IF EXISTS club_enroll;
CREATE DATABASE club_enroll
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE club_enroll;

-- ============================================
-- 1. user 用户表（学生 + 管理员公用一张表，用 role 区分）
-- ============================================
CREATE TABLE user (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    username    VARCHAR(32)  NOT NULL                COMMENT '用户名（唯一）',
    password    VARCHAR(64)  NOT NULL                COMMENT '密码（BCrypt 哈希）',
    role        VARCHAR(16)  NOT NULL                COMMENT '角色：student / admin',
    real_name   VARCHAR(32)  NOT NULL                COMMENT '真实姓名',
    phone       VARCHAR(11)  NOT NULL                COMMENT '手机号（11位）',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_username (username),
    KEY idx_role (role),
    KEY idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表（学生/管理员）';

-- ============================================
-- 2. club 社团表
-- ============================================
CREATE TABLE club (
    id              BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    name            VARCHAR(64)   NOT NULL                COMMENT '社团名（唯一）',
    category        VARCHAR(16)   NOT NULL                COMMENT '分类：学术/体育/文艺/公益',
    intro           VARCHAR(1000) NOT NULL                COMMENT '简介',
    leader          VARCHAR(32)   NOT NULL                COMMENT '负责人姓名',
    max_members     INT           NOT NULL                COMMENT '人数上限',
    current_members INT           NOT NULL DEFAULT 0      COMMENT '当前人数（审批通过自动+1）',
    is_active       TINYINT(1)    NOT NULL DEFAULT 1      COMMENT '是否在招：1=招新中 0=已下架',
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_club_name (name),
    KEY idx_category (category),
    KEY idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社团表';

-- ============================================
-- 3. enrollment 报名记录表
-- ============================================
CREATE TABLE enrollment (
    id            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    user_id       BIGINT       NOT NULL                COMMENT '学生ID',
    club_id       BIGINT       NOT NULL                COMMENT '社团ID',
    reason        VARCHAR(200) NOT NULL                COMMENT '报名理由（10-200字）',
    status        TINYINT      NOT NULL DEFAULT 1      COMMENT '状态：1=待审 2=通过 3=拒绝',
    apply_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '报名时间',
    review_time   DATETIME     NULL                    COMMENT '审批时间（未审为NULL）',
    reviewer_id   BIGINT       NULL                    COMMENT '审批人ID（未审为NULL）',
    review_remark VARCHAR(200) NULL                    COMMENT '审批备注（通过或拒绝原因）',
    PRIMARY KEY (id),
    -- 同一学生对同一社团不可重复报名
    UNIQUE KEY uk_user_club (user_id, club_id),
    KEY idx_status (status),
    KEY idx_club_id (club_id),
    KEY idx_apply_time (apply_time),
    CONSTRAINT fk_enroll_user     FOREIGN KEY (user_id)     REFERENCES user(id),
    CONSTRAINT fk_enroll_club     FOREIGN KEY (club_id)     REFERENCES club(id),
    CONSTRAINT fk_enroll_reviewer FOREIGN KEY (reviewer_id) REFERENCES user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报名记录表';

-- ============================================
-- 4. notice 公告表
-- ============================================
CREATE TABLE notice (
    id           BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    club_id      BIGINT      NOT NULL                COMMENT '社团ID',
    title        VARCHAR(64) NOT NULL                COMMENT '公告标题',
    content      TEXT        NOT NULL                COMMENT '公告正文',
    publisher_id BIGINT      NOT NULL                COMMENT '发布人ID（admin）',
    created_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    PRIMARY KEY (id),
    KEY idx_club_id (club_id),
    KEY idx_created_at (created_at),
    CONSTRAINT fk_notice_club      FOREIGN KEY (club_id)      REFERENCES club(id),
    CONSTRAINT fk_notice_publisher FOREIGN KEY (publisher_id) REFERENCES user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='公告表';

-- ============================================
-- 测试数据初始化
-- ============================================
USE club_enroll;

-- ============ 1. 用户：3 名学生 + 1 名管理员 ============
-- 本地演示账号：stu001 / stu002 / stu003 密码均为 123456，admin 密码为 admin123（数据库存 BCrypt 哈希）
INSERT INTO user (username, password, role, real_name, phone) VALUES
    ('stu001', '$2a$12$Obt421J7TJdTpWZHGUpmjOY5ssl/MZXFvFJkRA4AfW43jStUu65tC', 'student', '王雨桐', '13800138001'),
    ('stu002', '$2a$12$StDS1UtpGBnrOD0QsGmYJuFLG24pLUna1aw9So.Idkp4dUec4Dc0y', 'student', '李明轩', '13800138002'),
    ('stu003', '$2a$12$6WoBZQ..t95Ux66z0iZc9..Sx8lmHKx8cPvweXZ/3.fKM79sshcby', 'student', '赵思远', '13800138003'),
    ('admin',  '$2a$12$csNuzr9wUgxszLfftYNnPOaFhHluXgiTqubipxQBky/6ceQkrot4a', 'admin',   '社联管理员', '13900139001');

-- ============ 2. 社团：5 个，覆盖不同分类与招新状态 ============
INSERT INTO club (name, category, intro, leader, max_members, current_members, is_active) VALUES
    ('摄影协会',
     '文艺',
     '每周组织一次校园外拍，每学期举办一次作品展。器材不限，手机摄影同样欢迎，协会提供基础后期培训。',
     '陈墨',
     40, 26, 1),

    ('篮球社',
     '体育',
     '每周二、四傍晚在体育馆训练，每年举办校内 3V3 联赛。设有新手组，零基础同学可参加基础训练营。',
     '周浩然',
     60, 45, 1),

    ('程序设计协会',
     '学术',
     '组织算法训练、项目实战和赛前集训，每学期一次内部编程马拉松。欢迎零基础同学从 Python 入门。',
     '高远',
     50, 20, 1),

    ('青年志愿者协会',
     '公益',
     '每月组织一次社区服务或校园公益活动，寒暑假开展乡村支教与环保调研，累计志愿时长可开具证明。',
     '林小雨',
     100, 58, 1),

    ('话剧社',
     '文艺',
     '每学期排演一台话剧，参与校园文化艺术节演出。本学期排练已满员，暂停招新。',
     '徐一鸣',
     30, 30, 0);   -- 已下架样例：人数已满 + 不在招新期

-- ============ 3. 报名：8 条记录，覆盖三种审批状态 ============
-- 王雨桐（id=1）报了 3 个社团
INSERT INTO enrollment (user_id, club_id, reason, status, apply_time, review_time, reviewer_id, review_remark) VALUES
    (1, 1, '平时喜欢用手机拍校园风景，想系统学习构图和后期，希望加入后能参与作品展。', 2, '2026-05-20 10:00:00', '2026-05-21 14:30:00', 4, '作品有想法，欢迎加入'),
    (1, 2, '几乎没有基础，但想通过打球锻炼身体，请问新手组每周训练时间是什么？', 1, '2026-05-22 16:00:00', NULL, NULL, NULL),
    (1, 4, '高中参加过社区志愿服务，希望大学继续做公益，可以保证每月参加一次活动。', 1, '2026-05-23 09:30:00', NULL, NULL, NULL);

-- 李明轩（id=2）报了 2 个，1 通过 1 拒绝
INSERT INTO enrollment (user_id, club_id, reason, status, apply_time, review_time, reviewer_id, review_remark) VALUES
    (2, 3, '学过 C 语言和数据结构，想找队友一起做项目、准备算法比赛。', 2, '2026-05-18 19:00:00', '2026-05-19 11:00:00', 4, '基础扎实，通过'),
    (2, 2, '想加入篮球社，但我只有周末有时间，请问可以参加训练吗？', 3, '2026-05-19 20:00:00', '2026-05-20 10:00:00', 4, '周末训练名额已满，下学期欢迎重新报名');

-- 赵思远（id=3）报了 3 个
INSERT INTO enrollment (user_id, club_id, reason, status, apply_time, review_time, reviewer_id, review_remark) VALUES
    (3, 1, '做过一年校园记者，喜欢纪实摄影，想加入摄影协会继续拍校园题材。', 1, '2026-05-25 11:00:00', NULL, NULL, NULL),
    (3, 4, '想利用周末做一些有意义的事，之前参加过敬老院志愿服务。', 2, '2026-05-21 14:00:00', '2026-05-22 16:00:00', 4, '动机真诚，通过'),
    (3, 3, '零基础，想从 Python 开始学，请问协会有入门课程吗？', 1, '2026-05-26 08:00:00', NULL, NULL, NULL);

-- ============ 4. 公告：4 条 ============
INSERT INTO notice (club_id, title, content, publisher_id, created_at) VALUES
    (1, '摄影协会秋季校园外拍活动通知',
     '本周六下午 3 点在图书馆门口集合，前往老校区拍摄银杏大道。请自备相机或手机，活动结束后统一提交 3 张作品用于作品展评选。',
     4, '2026-06-10 14:00:00'),

    (2, '篮球社 3V3 联赛报名开始',
     '本届 3V3 联赛报名截止 6 月 25 日，每队 3-4 人，可自由组队。比赛时间为每周六下午，冠军队伍将获得奖杯与运动装备。',
     4, '2026-06-12 10:00:00'),

    (3, '程序设计协会暑期集训招募',
     '暑期集训时间为 7 月 1 日-7 月 20 日，内容涵盖算法基础、Web 开发与项目实战。名额 30 人，通过审批的同学请按时参加。',
     4, '2026-06-13 16:30:00'),

    (4, '暑期乡村支教志愿者招募',
     '本协会将于 7 月 15 日-7 月 30 日组织乡村支教活动，需要志愿者 15 名，负责课业辅导与兴趣课程。报名截止 6 月 30 日。',
     4, '2026-06-14 09:00:00');
