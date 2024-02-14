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
ORDER BY stolen_base_pct DESC
-- Chris Owings had the most success stealing bases in 2016 with a stolen base % of 91.3%.

-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series?
-- What is the smallest number of wins for a team that did win the world series?
-- Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case.
-- Then redo your query, excluding the problem year.
-- How often from 1970 to 2016 was it the case that a team with the most wins also won the world series?
-- What percentage of the time?
