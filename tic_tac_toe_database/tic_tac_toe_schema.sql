-- Tic Tac Toe PostgreSQL Schema
-- Supports: Player registration/storage, Game state, Move history, Leaderboard

-- Players table: user registration and player info
CREATE TABLE IF NOT EXISTS player (
    id SERIAL PRIMARY KEY,
    username VARCHAR(32) UNIQUE NOT NULL,
    email VARCHAR(64) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Games table: track games between two players, final state/result
CREATE TABLE IF NOT EXISTS game (
    id SERIAL PRIMARY KEY,
    player_x_id INTEGER REFERENCES player(id) ON DELETE SET NULL,
    player_o_id INTEGER REFERENCES player(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    finished_at TIMESTAMP,
    winner_id INTEGER REFERENCES player(id) ON DELETE SET NULL,
    -- state can be 'IN_PROGRESS', 'DRAW', or 'PLAYER_X_WON', etc.
    state VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS'
);

-- Moves table: stores each move within a game, supports move history
CREATE TABLE IF NOT EXISTS move (
    id SERIAL PRIMARY KEY,
    game_id INTEGER REFERENCES game(id) ON DELETE CASCADE,
    player_id INTEGER REFERENCES player(id) ON DELETE CASCADE,
    move_number INTEGER NOT NULL,
    -- Board coordinates (row and column 0-2)
    board_row INTEGER NOT NULL CHECK (board_row >= 0 AND board_row <= 2),
    board_col INTEGER NOT NULL CHECK (board_col >= 0 AND board_col <= 2),
    symbol CHAR(1) NOT NULL CHECK (symbol IN ('X', 'O')),
    moved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (game_id, move_number), -- only one move per slot
    UNIQUE (game_id, board_row, board_col) -- cannot move to the same cell twice
);

-- Leaderboard / Score table: tracks player scores/wins/losses/draws
CREATE TABLE IF NOT EXISTS score (
    player_id INTEGER PRIMARY KEY REFERENCES player(id) ON DELETE CASCADE,
    games_played INTEGER NOT NULL DEFAULT 0,
    wins INTEGER NOT NULL DEFAULT 0,
    losses INTEGER NOT NULL DEFAULT 0,
    draws INTEGER NOT NULL DEFAULT 0,
    last_played TIMESTAMP
);

-- Index for faster leaderboard lookup
CREATE INDEX IF NOT EXISTS score_wins_idx ON score(wins DESC, draws DESC);

-- View for leaderboard (optional, handy for queries)
CREATE OR REPLACE VIEW leaderboard AS
SELECT
    player.id,
    player.username,
    score.games_played,
    score.wins,
    score.losses,
    score.draws,
    COALESCE(score.wins, 0)::int AS rank_score
FROM player
LEFT JOIN score ON player.id = score.player_id
ORDER BY rank_score DESC, score.draws DESC, player.username ASC;

-- Triggers and procedures to automatically update the score table can be added in backend logic.

-- End of schema
