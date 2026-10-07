-- =========================================================================
-- 0011_producer_movie_metadata.sql
-- LiveScreen — Producer Movie Metadata (Language & Genre)
--
-- Adds optional language and genre columns to the movies table to support
-- the Producer Admin dashboard and movie categorization.
-- Preserves backwards compatibility with safe defaults and existing records.
-- =========================================================================

-- 1. Add language and genre columns to movies table with safe defaults
alter table movies add column if not exists language text not null default 'English';
alter table movies add column if not exists genre text not null default 'Drama';

-- 2. Indexes for fast filtering and analytics
create index if not exists movies_language_idx on movies (language);
create index if not exists movies_genre_idx on movies (genre);
