WITH recursive rnd_move(move) as (
  SELECT
    *,
    random() rnd
  FROM
    generate_series(1,16) move
),
game AS (
  SELECT
    0 AS turn,
    1 AS player_next,
    6 AS HITS_TO_WIN,
    16 AS BOARD_SIZE,
    ARRAY[
      'x','o','o','x',
      'x','o','o','x',
      'o','o','x','x',
      'o','o','o','o',
      --------------
      'o','x','x','o',
      'x','o','o','o',
      'x','o','x','o',
      'x','o','o','o'
    ] AS true_board,
    array_fill('-'::text, ARRAY[32]) AS player_board
  UNION(
    SELECT
      turn + 1,
      turn % 2,
      HITS_TO_WIN,
      BOARD_SIZE,
      true_board,
      player_board[:(move-1 + player_next*BOARD_SIZE)] || true_board[move + player_next*BOARD_SIZE] || player_board[(move+1 + player_next*BOARD_SIZE):]
    FROM
      game,
      rnd_move
    WHERE player_board[move] = '-'
    ORDER BY rnd LIMIT 1
  )
),
game_with_hits AS (
  SELECT
    *,
    array_length(array_positions(player_board[:BOARD_SIZE], 'x'), 1) AS hits_0,
    array_length(array_positions(player_board[(BOARD_SIZE+1):], 'x'), 1) AS hits_1
  FROM game
),
game_with_prev_hits AS (
  SELECT
    *,
    lag(hits_0) over () prev_hits_0,
    lag(hits_1) over () prev_hits_1
  FROM game_with_hits
),
results AS (
  SELECT
    turn,
    player_next,
    hits_0,
    hits_1,
    true_board[:BOARD_SIZE] AS tb_0,
    player_board[:BOARD_SIZE] AS pb_0,
    true_board[(BOARD_SIZE+1):] AS tb_1,
    player_board[(BOARD_SIZE+1):] AS pb_1,
    CASE
      WHEN (hits_0 >= HITS_TO_WIN OR hits_1 >= HITS_TO_WIN)
        THEN 'Player ' || (player_next + 1) % 2 || ' wins!'
      END AS winner
    FROM game_with_prev_hits
    WHERE
      (HITS_TO_WIN > prev_hits_0 AND HITS_TO_WIN > prev_hits_1)
      OR (prev_hits_0 IS null AND prev_hits_1 IS null)
      OR (prev_hits_0 is NULL AND HITS_TO_WIN > prev_hits_1)
      OR (prev_hits_1 is NULL AND HITS_TO_WIN > prev_hits_0 )
    ORDER BY turn asc
)
SELECT
  turn,
  (player_next + 1) % 2 AS player,
  array_to_string(pb_0[1:4] 
    || chr(10) || pb_0[5:8] 
    || chr(10) || pb_0[9:12] 
    || chr(10) || pb_0[13:16] 
    || chr(10), '') player_board_0,
  array_to_string(pb_1[1:4] 
    || chr(10) || pb_1[5:8] 
    || chr(10) || pb_1[9:12] 
    || chr(10) || pb_0[13:16] 
    || chr(10), '') player_board_1,
  winner
FROM results;