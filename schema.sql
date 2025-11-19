-- Database Schema for Digg-like Social News Platform

-- Users table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_digest VARCHAR(255) NOT NULL,
    display_name VARCHAR(100),
    avatar_url VARCHAR(500),
    bio TEXT,
    website_url VARCHAR(500),
    karma_score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_karma ON users(karma_score DESC);

-- Categories for organizing articles
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    parent_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_parent ON categories(parent_id);

-- Submitted articles
CREATE TABLE articles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    url VARCHAR(2048) NOT NULL,
    description TEXT,
    thumbnail_url VARCHAR(500),
    domain VARCHAR(255),
    vote_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    hotness_score FLOAT DEFAULT 0.0,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected, deleted
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_articles_user ON articles(user_id);
CREATE INDEX idx_articles_category ON articles(category_id);
CREATE INDEX idx_articles_hotness ON articles(hotness_score DESC);
CREATE INDEX idx_articles_vote_count ON articles(vote_count DESC);
CREATE INDEX idx_articles_created ON articles(created_at DESC);
CREATE INDEX idx_articles_status ON articles(status);
CREATE INDEX idx_articles_domain ON articles(domain);

-- Votes on articles
CREATE TABLE article_votes (
    id BIGSERIAL PRIMARY KEY,
    article_id BIGINT NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vote_type SMALLINT NOT NULL CHECK (vote_type IN (-1, 1)), -- -1 = dislike, 1 = like
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(article_id, user_id)
);

CREATE INDEX idx_article_votes_article ON article_votes(article_id);
CREATE INDEX idx_article_votes_user ON article_votes(user_id);
CREATE INDEX idx_article_votes_type ON article_votes(vote_type);

-- Comments on articles
CREATE TABLE comments (
    id BIGSERIAL PRIMARY KEY,
    article_id BIGINT NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id BIGINT REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    vote_count INTEGER DEFAULT 0,
    depth INTEGER DEFAULT 0,
    path TEXT, -- materialized path for efficient tree queries (e.g., '1.5.12')
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_comments_article ON comments(article_id);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_parent ON comments(parent_id);
CREATE INDEX idx_comments_path ON comments(path);
CREATE INDEX idx_comments_vote_count ON comments(vote_count DESC);

-- Votes on comments
CREATE TABLE comment_votes (
    id BIGSERIAL PRIMARY KEY,
    comment_id BIGINT NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vote_type SMALLINT NOT NULL CHECK (vote_type IN (-1, 1)), -- -1 = dislike, 1 = like
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(comment_id, user_id)
);

CREATE INDEX idx_comment_votes_comment ON comment_votes(comment_id);
CREATE INDEX idx_comment_votes_user ON comment_votes(user_id);

-- User subscriptions/follows
CREATE TABLE user_follows (
    id BIGSERIAL PRIMARY KEY,
    follower_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX idx_user_follows_follower ON user_follows(follower_id);
CREATE INDEX idx_user_follows_following ON user_follows(following_id);

-- Category subscriptions
CREATE TABLE category_subscriptions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, category_id)
);

CREATE INDEX idx_category_subs_user ON category_subscriptions(user_id);
CREATE INDEX idx_category_subs_category ON category_subscriptions(category_id);

-- Saved/bookmarked articles
CREATE TABLE saved_articles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    article_id BIGINT NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, article_id)
);

CREATE INDEX idx_saved_articles_user ON saved_articles(user_id);
CREATE INDEX idx_saved_articles_article ON saved_articles(article_id);

-- User activity log (for karma calculation and analytics)
CREATE TABLE user_activities (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- article_submit, article_vote, comment_post, comment_vote
    entity_type VARCHAR(50) NOT NULL, -- article, comment
    entity_id BIGINT NOT NULL,
    points INTEGER DEFAULT 0, -- karma points awarded
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activities_user ON user_activities(user_id);
CREATE INDEX idx_activities_type ON user_activities(activity_type);
CREATE INDEX idx_activities_created ON user_activities(created_at DESC);

-- Tags for articles
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tags_slug ON tags(slug);
CREATE INDEX idx_tags_usage ON tags(usage_count DESC);

-- Many-to-many relationship between articles and tags
CREATE TABLE article_tags (
    article_id BIGINT NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (article_id, tag_id)
);

CREATE INDEX idx_article_tags_article ON article_tags(article_id);
CREATE INDEX idx_article_tags_tag ON article_tags(tag_id);

-- Reported content (moderation)
CREATE TABLE reports (
    id BIGSERIAL PRIMARY KEY,
    reporter_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reportable_type VARCHAR(50) NOT NULL, -- Article, Comment, User
    reportable_id BIGINT NOT NULL,
    reason VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, resolved, dismissed
    resolved_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_reportable ON reports(reportable_type, reportable_id);
CREATE INDEX idx_reports_reporter ON reports(reporter_id);
