-- 1. Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. 
-- Which Vanderbilt player earned the most money in the majors?
SELECT namefirst, namelast, SUM(salary) AS total_salary
FROM people
INNER JOIN collegeplaying
USING(playerid)
INNER JOIN salaries
USING(playerid)
WHERE schoolid = 'vandy'
GROUP BY playerid
ORDER BY total_salary DESC;
-- David Price is the Vandy player that earned the most in the majors.

-- 2. Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.
SELECT SUM(po) AS putout_count,
CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
	WHEN pos IN ('P', 'C') THEN 'Battery'
	END AS position_group
FROM fielding
WHERE yearid = '2016'
GROUP BY position_group;
-- In 2016, there were 41,424 putouts by battery players, 58,934 putouts by infield players, and 29,560 putouts by outfield players.

-- 3. Find the average number of strikeouts per game by decade since 1920. 
-- Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends?
WITH decade AS (
	SELECT GENERATE_SERIES(1920, 2010, 10) AS decade_start,
		GENERATE_SERIES(1929, 2019, 10) AS decade_end
)

SELECT decade_start, 
	ROUND(SUM(SO)/CAST(SUM(G) AS DECIMAL),2) AS strikeouts_per_game, 
	ROUND(SUM(HR)/CAST(SUM(G) AS DECIMAL),2) AS homeruns_per_game
FROM teams
LEFT JOIN decade
ON yearID BETWEEN decade_start AND decade_end
WHERE yearID>=1920
GROUP BY decade_start
ORDER BY decade_start DESC;
--Number of strikeouts and homeruns per game generally increase each decade.

-- 4. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful.
-- (A stolen base attempt results either in a stolen base or being caught stealing.)
-- Consider only players who attempted at least 20 stolen bases.
-- Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.
WITH stolen_bases_2016 AS (
SELECT playerID, 
	COALESCE(SUM(SB),0) AS stolen_base, 
	COALESCE(SUM(CS),0) AS caught_stealing, 
	COALESCE(SUM(SB),0) + COALESCE(SUM(CS),0) AS stolen_base_attempts
FROM batting
WHERE yearID = 2016
GROUP BY playerID)

SELECT namefirst, 
	namelast, 
	stolen_base, 
	caught_stealing, 
	stolen_base_attempts, 
	stolen_base*1.0/(stolen_base + caught_stealing) AS stolen_base_pct
FROM people
LEFT JOIN stolen_bases_2016
USING(playerID)
WHERE stolen_base_attempts >=20
ORDER BY stolen_base_pct DESC;
-- Chris Owings had the most success stealing bases in 2016 with a stolen base % of 91.3%.

-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series?
-- What is the smallest number of wins for a team that did win the world series?
-- Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case.
-- Then redo your query, excluding the problem year.
-- How often from 1970 to 2016 was it the case that a team with the most wins also won the world series?
-- What percentage of the time?
SELECT yearid, name, W AS wins
FROM teams
WHERE WSwin = 'N'
	AND yearid BETWEEN 1970 AND 2016
ORDER BY wins DESC;
-- Between 1970 and 2016, the largest number of wins in a season acheived by a team that did not win the world series was the 2001 Seattle Mariners.

SELECT yearid, name, W AS wins
FROM teams
WHERE WSwin = 'Y'
	AND yearid BETWEEN 1970 AND 2016
	AND yearid != 1981
ORDER BY wins;
-- The smallest number of wins for a team that won the world series was the LA Dodgers with just 63 wins in 1981, but this was because of the 1981 baseball players' strike.
-- Besides 1981, the smallest number of wins for a team that won the world series was the St. Louis Cardinals with 83 wins in 2006.

WITH most_win_team AS (
	SELECT yearid, name, most_wins
	FROM teams
	INNER JOIN(
		SELECT yearid, MAX(W) AS most_wins
		FROM teams
		GROUP BY yearid)
	USING(yearid)
	WHERE most_wins = W
),

ws_win_team AS (
	SELECT yearid, name, WSwin
	FROM teams
	WHERE WSwin = 'Y'
)
SELECT number_ws_winners_as_most_winners, 
	ROUND(number_ws_winners_as_most_winners*1.0/number_of_distinct_years,3) AS pct_ws_winners_as_most_winners
FROM(
SELECT
	COUNT(DISTINCT(yearid)) AS number_of_distinct_years,
	COUNT(CASE WHEN m.name = w.name THEN 1.0 END) AS number_ws_winners_as_most_winners
FROM most_win_team AS m
INNER JOIN ws_win_team AS w
USING(yearid)
WHERE yearid BETWEEN 1970 AND 2016)
-- Only 12 teams between 1970 and 2016 won the most games in the season and also won the world series.
-- This means only 26.1% of world series winners also won the most games in the same season.

-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)?
-- Give their full name and the teams that they were managing when they won the award.
WITH AL_TSN_ManagerotY AS (
SELECT playerid, name AS ALteam_name, yearid, awardsmanagers.lgid
FROM awardsmanagers
INNER JOIN managers
USING(playerid, yearid)
INNER JOIN teams
USING(teamid, yearid)
WHERE awardid = 'TSN Manager of the Year'
	AND awardsmanagers.lgid = 'AL'),

NL_TSN_ManagerotY AS (
SELECT playerid, name AS NLteam_name, yearid, awardsmanagers.lgid
FROM awardsmanagers
INNER JOIN managers
USING(playerid, yearid)
INNER JOIN teams
USING(teamid, yearid)
WHERE awardid = 'TSN Manager of the Year'
	AND awardsmanagers.lgid = 'NL')

SELECT DISTINCT namefirst,
	namelast,
	ALteam_name,
	NLteam_name
FROM AL_TSN_ManagerotY
INNER JOIN NL_TSN_ManagerotY
USING(playerid)
INNER JOIN people
USING(playerid);
-- Davey Johnson won TSN Manager of the Year while managing both the Baltimore Orioles (AL) and the Washington Nationals (NL)
-- Jim Leyland won TSN Manager of the Year while managing both the Detroit Tigers (AL) and the Pittsburgh Pirates (NL)

-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts?
-- Only consider pitchers who started at least 10 games (across all teams).
-- Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

