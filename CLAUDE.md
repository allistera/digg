# Digg Clone - Database Schema

## Overview
Database structure for a Digg-like social news platform where members can submit articles, vote (like/dislike), and comment.

## Core Tables

### users
Member profiles with karma scoring, authentication, and verification status
- Tracks karma score for reputation system
- Includes avatar, bio, and profile information
- Supports account verification and active/inactive states

### articles
Submitted content with comprehensive metadata:
- Vote/comment/view counters (denormalized for performance)
- Hotness score for ranking algorithms
- Status workflow (pending → approved → published)
- Domain tracking for duplicate detection
- Thumbnail and description for rich previews

### article_votes
Like/dislike voting on articles
- vote_type: -1 (dislike) or 1 (like)
- Unique constraint prevents duplicate votes per user

### comments
Nested comment system with:
- Parent/child relationships for threading
- Materialized path for efficient tree traversal
- Vote count tracking
- Depth tracking for display purposes
- Soft deletion support (preserves conversation context)

### comment_votes
Voting on individual comments
- Same vote_type pattern as article_votes
- Unique constraint per user/comment

## Organization & Discovery

### categories
Hierarchical categorization system
- Supports parent/child relationships for subcategories
- Includes slug for URL-friendly routing
- Display order for custom sorting

### tags
Flexible tagging system
- Usage count for trending tags
- Slug for URL routing

### article_tags
Many-to-many relationship between articles and tags

## Social Features

### user_follows
User-to-user following relationships
- Enables following other members
- Check constraint prevents self-following

### category_subscriptions
Subscribe to categories of interest for personalized feeds

### saved_articles
Bookmark articles for later reading

## Moderation & Analytics

### reports
Content moderation workflow
- Report articles, comments, or users
- Status tracking (pending → resolved/dismissed)
- Tracks resolver for accountability

### user_activities
Activity log for karma calculation and analytics
- Tracks all user actions (submits, votes, comments)
- Points field for karma calculations
- Enables analytics and reputation systems

## Key Design Decisions

1. **Denormalized counters** - vote_count, comment_count, view_count on articles and comments for performance (avoid expensive COUNT queries)

2. **Hotness score** - Pre-calculated field for implementing ranking algorithms (Reddit-style time-decay)

3. **Materialized path** - Comments use path field (e.g., '1.5.12') for efficient tree queries without recursive CTEs

4. **Unique constraints** - Prevent duplicate votes (one vote per user per article/comment)

5. **Comprehensive indexes** - Optimized for common query patterns:
   - Sorting by votes, hotness, date
   - Filtering by category, user, status
   - Comment tree traversal

6. **Karma system** - user_activities table tracks all actions with point values for reputation scoring

7. **Soft deletion** - Comments use is_deleted flag to preserve conversation context while hiding content

8. **Status workflow** - Articles go through pending → approved flow for content moderation

## Schema File
See `schema.sql` for complete PostgreSQL schema with all tables, indexes, and constraints.
